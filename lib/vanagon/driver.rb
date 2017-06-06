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
    attr_accessor :timeout, :retry_count

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
        $stderr.puts "Only building:"
        @project.components.each { |comp| $stderr.puts comp.name }
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
    rescue
      fail "No such engine '#{camelize(engine_type)}'"
    end

    def camelize(string)
      string.gsub(/(?:^|_)([a-z])?/) do |match|
        (Regexp.last_match[1] || '').capitalize
      end
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

    def build_host_info
      { "name" => @engine.build_host_name, "engine" => @engine.name }
    end

    # Normalize our pkgname=version syntax to work with the package
    # manager being used for this platform.
    def normalize_build_dependencies_syntax(build_deps)
      if @platform.build_dependencies.command =~ /apt/
        # apt uses '=' as the package/version separator, no need to do anything
      elsif @platform.build_dependencies.command =~ /yum|dnf|zypper/
        # yum/dnf/zypper uses '-' as the package/version separator
        build_deps = build_deps.map { |pkg| pkg.sub('=', '-') }
      else
        raise Vanagon::Error, "Support for specifying package versions in build_requires is not available for #{@platform.name}"
      end

      build_deps
    end

    # Returns a list of external dependencies that need to be installed.
    # If version numbers are specified, this method ensures the package
    # names use the correct format for the platform's package manager.
    def list_build_dependencies
      build_requires = @project.components.map(&:build_requires).flatten.uniq
      component_names = @project.components.map(&:name)
      build_deps = []
      version_specified = false

      build_requires.each do |pkg|
        version_specified = true if pkg.include?('=')
        # Skip any package names that match the name of a component
        unless component_names.include?(pkg.split('=')[0])
          build_deps << pkg
        end
      end

      if version_specified
        build_deps = normalize_build_dependencies_syntax(build_deps)
      end

      build_deps
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

    def run # rubocop:disable Metrics/AbcSize
      # Simple sanity check for the project
      if @project.version.nil? or @project.version.empty?
        raise Vanagon::Error, "Project requires a version set, all is lost."
      end

      @engine.startup(@workdir)

      $stderr.puts "Target is #{@engine.target}"
      retry_task { install_build_dependencies }
      retry_task { @project.fetch_sources(@workdir) }

      @project.make_makefile(@workdir)
      @project.make_bill_of_materials(@workdir)
      @project.generate_packaging_artifacts(@workdir)
      @engine.ship_workdir(@workdir)
      @engine.dispatch("(cd #{@engine.remote_workdir}; #{@platform.make})")
      @engine.retrieve_built_artifact

      unless @preserve
        @engine.teardown
        cleanup_workdir
      end
    rescue => e
      $stderr.puts e
      $stderr.puts e.backtrace.join("\n")
      raise e
    ensure
      if ["hardware", "ec2"].include?(@engine.name)
        @engine.teardown
      end
    end

    def render
      # Simple sanity check for the project
      if @project.version.nil? or @project.version.empty?
        raise Vanagon::Error, "Project requires a version set, all is lost."
      end

      $stderr.puts "rendering Makefile"
      retry_task { @project.fetch_sources(@workdir) }
      @project.make_bill_of_materials(@workdir)
      @project.generate_packaging_artifacts(@workdir)
      @project.make_makefile(@workdir)
    end

    def prepare(workdir = nil) # rubocop:disable Metrics/AbcSize
      @workdir = workdir ? FileUtils.mkdir_p(workdir).first : Dir.mktmpdir
      @engine.startup(@workdir)

      $stderr.puts "Devkit on #{@engine.target}"

      install_build_dependencies
      @project.fetch_sources(@workdir)
      @project.make_makefile(@workdir)
      @project.make_bill_of_materials(@workdir)
      # Builds only the project, skipping packaging into an artifact.
      @engine.ship_workdir(@workdir)
      @engine.dispatch("(cd #{@engine.remote_workdir}; #{@platform.make} #{@project.name}-project)")
    rescue => e
      $stderr.puts e
      $stderr.puts e.backtrace.join("\n")
      raise e
    end

    # Retry the provided block, use the retry count and timeout
    # values from the project, if available, otherwise use some
    # sane defaults.
    def retry_task(&block)
      @timeout = @project.timeout || ENV["VANAGON_TIMEOUT"] || 7200
      @retry_count = @project.retry_count || ENV["VANAGON_RETRY_COUNT"] || 1
      Vanagon::Utilities.retry_with_timeout(@retry_count, @timeout) { yield }
    end
    private :retry_task

    # Initialize the logging instance
    def loginit(logfile)
      @@logger = Logger.new(logfile)
      @@logger.progname = 'vanagon'
    end
    private :loginit
  end
end
