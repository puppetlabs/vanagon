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

    def initialize(platform, project, configdir, target = nil, engine = 'pooler')
      @verbose = false
      @preserve = false

      @@configdir = configdir

      @platform = Vanagon::Platform.load_platform(platform, File.join(@@configdir, "platforms"))
      @project = Vanagon::Project.load_project(project, File.join(@@configdir, "projects"), @platform)

      # If a target has been given, we don't want to make any assumptions about how to tear it down.
      engine = 'base' if target
      require "vanagon/engine/#{engine}"
      @engine = Object.const_get("Vanagon::Engine::#{engine.capitalize}").new(@platform, target)

      @@logger = Logger.new('vanagon_hosts.log')
      @@logger.progname = 'vanagon'
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

    def run
      begin
        # Simple sanity check for the project
        if @project.version.nil? or @project.version.empty?
          raise Vanagon::Error.new "Project requires a version set, all is lost."
        end
        @engine.startup
        @workdir = Dir.mktmpdir

        login = "#{@engine.target_user}@#{@engine.target}"

        puts "Target is #{@engine.target}"

        FileUtils.mkdir_p("output")
        install_build_dependencies(login)
        @project.fetch_sources(@workdir)
        @project.make_makefile(@workdir)
        @project.generate_packaging_artifacts(@workdir)
        ship_workdir_to(login)
        build_artifact_on(login)
        retrieve_built_artifact_from(login)
        @engine.teardown unless @preserve
        cleanup_workdir unless @preserve
      rescue => e
        puts e
        puts e.backtrace.join("\n")
        raise e
      end
    end
  end
end
