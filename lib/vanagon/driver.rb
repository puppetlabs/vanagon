require 'vanagon/project'
require 'vanagon/platform'
require 'vanagon/component'
require 'vanagon/utilities'
require 'vanagon/common'
require 'tmpdir'
require 'logger'

class Vanagon
  class Driver
    include Vanagon::Utilities
    attr_accessor :platform, :project, :target, :workdir

    # Future options: configdir, backend for virtualization

    def initialize(platform, project, configdir)
      @platform_name = platform
      @project_name = project
      @workdir = Dir.mktmpdir
      @@configdir = configdir
      @logger = Logger.new('vanagon_hosts.log')
      @logger.progname = 'vanagon'
    end

    def load_platform
      @platform = Vanagon::Platform.load_platform(@platform_name, File.join(@@configdir, "platforms"))
    end

    def load_project
      @project = Vanagon::Project.load_project(@project_name, File.join(@@configdir, "projects"), @platform)
      if @project.version.nil? or @project.version.empty?
        fail "Project requires a version set, all is lost."
      end
    end

    def cleanup_workdir
      FileUtils.rm_rf(@workdir)
    end

    def self.configdir
      @@configdir
    end

    def get_target
      if @platform.docker_image
        ex("docker run -d --name #{@platform.docker_image}-builder -p #{@platform.ssh_port}:22 #{@platform.docker_image}")
        # If you don't sleep, ssh doesn't start up in time
        ex('sleep 2')
        return "localhost"
      else
        target = http_request("http://vmpooler.delivery.puppetlabs.net/vm/#{@platform.vcloud_name}", "POST")
        if target and target["ok"]
          @logger.info "Reserving #{target[@platform.vcloud_name]["hostname"]} (#{@platform.vcloud_name})"
          return target[@platform.vcloud_name]["hostname"]
        else
          puts "something went wrong, maybe the pool for #{@platform.vcloud_name} is empty?"
          return false
        end
      end
    end

    def template_to_builder(target)
      script = @platform.provisioning.join(' ; ')
      remote_ssh_command(target, script, @platform.ssh_port)
    end

    # Returns the set difference between the build_requires and the components to get a list of external dependencies that need to be installed.
    def list_build_dependencies
      @project.components.map {|comp| comp.build_requires }.flatten.uniq - @project.components.map {|comp| comp.name }
    end

    def install_build_dependencies(target)
      remote_ssh_command(target, "#{@platform.build_dependencies} #{list_build_dependencies.join(' ')}", @platform.ssh_port)
    end

    def ship_workdir_to(target)
      rsync_to("#{@workdir}/*", target, "~/", @platform.ssh_port )
    end

    def build_artifact_on(target)
      remote_ssh_command(target, "time #{@platform.make}", @platform.ssh_port)
    end

    def retrieve_built_artifact_from(target)
      rsync_from("output/*", target, "output", @platform.ssh_port )
    end

    def teardown_template(host)
      if @platform.docker_image
        ex("docker stop #{@platform.docker_image}-builder; docker rm #{@platform.docker_image}-builder")
        return true
      else
        target = http_request("http://vmpooler.delivery.puppetlabs.net/vm/#{host}", "DELETE")
        if target and target["ok"]
          @logger.info  "#{host} has been destroyed"
          puts "'#{host}' has been destroyed"
          return true
        else
          puts "something went wrong"
          return false
        end
      end
    end

    def run(target = nil, preserve = false)
      begin
        load_platform
        load_project

        unless target
          target = get_target
        end

        login = "root@#{target}"

        puts "Target is #{target}"

        # All about the target
        FileUtils.mkdir_p("output")
        template_to_builder(login)
        install_build_dependencies(login)
        @project.fetch_sources(@workdir)
        @project.make_makefile(@workdir)
        @project.generate_packaging_artifacts(@workdir)
        ship_workdir_to(login)
        build_artifact_on(login)
        retrieve_built_artifact_from(login)
        teardown_template(target) unless preserve
        cleanup_workdir unless preserve
      rescue => e
        puts e
        puts e.backtrace.join("\n")
        raise e
      end
    end

  end
end
