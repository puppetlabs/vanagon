require 'vanagon/project'
require 'vanagon/platform'
require 'vanagon/component'
require 'vanagon/utilities'
require 'vanagon/common'
require 'vanagon/errors'
require 'tmpdir'
require 'logger'

class Vanagon
  class Driver
    include Vanagon::Utilities
    attr_accessor :platform, :project, :target, :workdir

    def initialize(platform, project, configdir, engine)
      @platform_name = platform
      @project_name = project
      @workdir = Dir.mktmpdir
      @engine_name = engine
      @@configdir = configdir
      @@logger = Logger.new('vanagon_hosts.log')
      @@logger.progname = 'vanagon'
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

    def load_engine(target = nil)
      # If a target has been given, we don't want to make any assumptions about how to tear it down.
      if target
        @engine_name = 'base'
      end
      require "vanagon/engine/#{@engine_name}"
      @engine = Object.const_get("Vanagon::Engine::#{@engine_name.capitalize}").new(@platform, target)
    rescue LoadError => e
      raise Vanagon::Error.wrap(e, "Could not load the desired engine '#{@engine_name}'.")
    end

    def cleanup_workdir
      FileUtils.rm_rf(@workdir)
    end

    def self.configdir
      @@configdir
    end

    def self.logger
      @@logger
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

    def run(target = nil, preserve = false)
      begin
        load_platform
        load_engine(target)
        @engine.startup
        load_project

        login = "#{@engine.target_user}@#{@engine.target}"

        puts "Target is #{@engine.target}"

        # All about the target
        FileUtils.mkdir_p("output")
        install_build_dependencies(login)
        @project.fetch_sources(@workdir)
        @project.make_makefile(@workdir)
        @project.generate_packaging_artifacts(@workdir)
        ship_workdir_to(login)
        build_artifact_on(login)
        retrieve_built_artifact_from(login)
        @engine.teardown unless preserve
        cleanup_workdir unless preserve
      rescue => e
        puts e
        puts e.backtrace.join("\n")
        raise e
      end
    end
  end
end
