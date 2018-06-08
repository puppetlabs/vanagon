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
    attr_accessor :platform, :project, :target, :workdir, :remote_workdir, :verbose, :preserve

    def timeout
      @timeout ||= @project.timeout || ENV["VANAGON_TIMEOUT"] || 7200
    end

    def retry_count
      @retry_count ||= @project.retry_count || ENV["VANAGON_RETRY_COUNT"] || 1
    end

    def initialize(platform, project, options = { workdir: nil, configdir: nil, target: nil, engine: nil, components: nil, skipcheck: false, verbose: false, preserve: false, only_build: nil, remote_workdir: nil }) # rubocop:disable Metrics/AbcSize
      @verbose = options[:verbose]
      @preserve = options[:preserve]
      @workdir = options[:workdir] || Dir.mktmpdir

      @@configdir = options[:configdir] || File.join(Dir.pwd, "configs")
      components = options[:components] || []
      only_build = options[:only_build]
      target = options[:target]
      engine = options[:engine] || 'pooler'

      @platform = Vanagon::Platform.load_platform(platform, File.join(@@configdir, "platforms"))
      @project = Vanagon::Project.load_project(project, File.join(@@configdir, "projects"), @platform, components)
      @project.settings[:verbose] = options[:verbose]
      @project.settings[:skipcheck] = options[:skipcheck]
      filter_out_components(only_build) if only_build
      loginit('vanagon_hosts.log')

      @remote_workdir = options[:"remote-workdir"]

      load_engine(engine, @platform, target)
    rescue LoadError => e
      raise Vanagon::Error.wrap(e, "Could not load the desired engine '#{engine}'")
    end

    def filter_out_components(only_build)
      # map each element in the only_build array to it's set of filtered components, then
      # flatten all the results in to one array and set project.components to that.
      @project.components = only_build.flat_map { |comp| @project.filter_component(comp) }.uniq
      if @verbose
        warn "Only building:"
        @project.components.each { |comp| warn comp.name }
      end
    end

    def load_engine(engine_type, platform, target)
      if engine_type != 'always_be_scheduling'
        if platform.build_hosts
          engine_type = 'hardware'
        elsif platform.aws_ami
          engine_type = 'ec2'
        elsif platform.docker_image
          engine_type = 'docker'
        elsif target
          engine_type = 'base'
        end
      end
      load_engine_object(engine_type, platform, target)
    end

    def load_engine_object(engine_type, platform, target)
      require "vanagon/engine/#{engine_type}"
      @engine = Object::const_get("Vanagon::Engine::#{camelize(engine_type)}").new(platform, target, remote_workdir: remote_workdir)
    rescue StandardError
      fail "No such engine '#{camelize(engine_type)}'"
    end

    def camelize(string)
      string.gsub(/(?:^|_)([a-z])?/) do |match|
        (Regexp.last_match[1] || '').capitalize
      end
    end

    def cleanup_workdir
      FileUtils.rm_rf(workdir)
    end

    def self.configdir
      @@configdir
    end

    def self.logger
      @@logger
    end

    def build_host_info
      { "name" => @engine.build_host_name, "engine" => @engine.name }
    end

    # Returns the set difference between the build_requires and the components to get a list of external dependencies that need to be installed.
    def list_build_dependencies
      @project.components.map(&:build_requires).flatten.uniq - @project.components.map(&:name)
    end

    def install_build_dependencies # rubocop:disable Metrics/AbcSize
      unless list_build_dependencies.empty?
        if @platform.build_dependencies && @platform.build_dependencies.command && !@platform.build_dependencies.command.empty?
          @engine.dispatch("#{@platform.build_dependencies.command} #{list_build_dependencies.join(' ')} #{@platform.build_dependencies.suffix}")
        elsif @platform.respond_to?(:install_build_dependencies)
          @engine.dispatch(@platform.install_build_dependencies(list_build_dependencies))
        else
          raise Vanagon::Error, "No method defined to install build dependencies for #{@platform.name}"
        end
      end
    end

    def run # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
      # Simple sanity check for the project
      if @project.version.nil? or @project.version.empty?
        raise Vanagon::Error, "Project requires a version set, all is lost."
      end

      # if no_packaging has been set in the project, don't execute the
      # whole makefile. Instead just perform the installation.
      make_target = ''
      if @project.no_packaging
        make_target = @project.name + '-project'
      end

      @engine.startup(workdir)
      warn "Target is #{@engine.target}"
      Vanagon::Utilities.retry_with_timeout(retry_count, timeout) do
        install_build_dependencies
      end
      @project.fetch_sources(workdir, retry_count, timeout)

      @project.make_makefile(workdir)
      @project.make_bill_of_materials(workdir)
      # Don't generate packaging artifacts if no_packaging is set
      @project.generate_packaging_artifacts(workdir) unless @project.no_packaging
      @project.save_manifest_json
      @engine.ship_workdir(workdir)
      @engine.dispatch("(cd #{@engine.remote_workdir}; #{@platform.make} #{make_target})")
      @engine.retrieve_built_artifact(@project.artifacts_to_fetch, @project.no_packaging)
      @project.publish_yaml_settings(workdir, @platform)

      if %i[never on-failure].include? @preserve
        @engine.teardown
        cleanup_workdir
      end
    rescue StandardError => e
      if [:never].include? @preserve
        @engine.teardown
        cleanup_workdir
      end
      warn e
      warn e.backtrace.join("\n")
      raise e
    ensure
      if ["hardware", "ec2"].include?(@engine.name)
        @engine.teardown
      end
    end

    def render # rubocop:disable Metrics/AbcSize
      # Simple sanity check for the project
      if @project.version.nil? or @project.version.empty?
        raise Vanagon::Error, "Project requires a version set, all is lost."
      end

      warn "rendering Makefile"
      @project.fetch_sources(workdir, retry_count, timeout)
      @project.make_bill_of_materials(workdir)
      @project.publish_yaml_settings(workdir, @project.platform)
      @project.generate_packaging_artifacts(workdir)
      @project.make_makefile(workdir)
    end

    # Initialize the logging instance
    def loginit(logfile)
      @@logger = Logger.new(logfile)
      @@logger.progname = 'vanagon'
    end
    private :loginit
  end
end
