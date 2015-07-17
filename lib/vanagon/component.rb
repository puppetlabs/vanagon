require 'vanagon/component/source'
require 'vanagon/component/dsl'

class Vanagon
  class Component
    attr_accessor :name, :version, :source, :url, :configure, :build, :install
    attr_accessor :environment, :extract_with, :dirname, :build_requires
    attr_accessor :settings, :platform, :files, :patches, :requires, :service, :options
    attr_accessor :configfiles, :directories, :replaces, :provides, :cleanup_source, :environment

    # Loads a given component from the configdir
    #
    # @param name [String] the name of the component
    # @param configdir [String] the path to the component config file
    # @param settings [Hash] the settings to be used in the component
    # @param platform [Vanagon::Platform] the platform to build the component for
    # @return [Vanagon::Component] the component as specified in the component config
    # @raise if the instance_eval on Component fails, the exception is reraised
    def self.load_component(name, configdir, settings, platform)
      compfile = File.join(configdir, "#{name}.rb")
      code = File.read(compfile)
      dsl = Vanagon::Component::DSL.new(name, settings, platform)
      dsl.instance_eval(code)
      dsl._component
    rescue => e
      puts "Error loading project '#{name}' using '#{compfile}':"
      puts e
      puts e.backtrace.join("\n")
      raise e
    end

    # Component constructor.
    #
    # @param name [String] the name of the component
    # @param settings [Hash] the settings to be used in the component
    # @param platform [Vanagon::Platform] the platform to build the component for
    # @return [Vanagon::Component] the component with the given settings and platform
    def initialize(name, settings, platform)
      @name = name
      @settings = settings
      @platform = platform
      @options = {}
      @build_requires = []
      @requires = []
      @configure = []
      @install = []
      @build = []
      @patches = []
      @files = []
      @configfiles = []
      @directories = []
      @replaces = []
      @provides = []
      @environment = {}
    end

    # Fetches the primary source for the component. As a side effect, also sets
    # \@extract_with, @dirname and @version for the component for use in the
    # makefile template
    #
    # @param workdir [String] working directory to put the source into
    def get_source(workdir)
      @source = Vanagon::Component::Source.source(@url, @options, workdir)
      @source.fetch
      @source.verify
      @extract_with = @source.extract(@platform.tar) if @source.respond_to?(:extract)
      @cleanup_source = @source.cleanup if @source.respond_to?(:cleanup)
      @dirname = @source.dirname

      # Git based sources probably won't set the version, so we load it if it hasn't been already set
      @version ||= @source.version
    end

    # Fetches patches if any are provided for the project.
    #
    # @param workdir [String] working directory to put the patches into
    def get_patches(workdir)
      unless @patches.empty?
        patchdir = File.join(workdir, "patches")
        FileUtils.mkdir_p(patchdir)
        FileUtils.cp(@patches, patchdir)
      end
    end

    # Prints the environment in a way suitable for use in a Makefile
    # or shell script.
    #
    # @return [String] environment suitable for inclusion in a Makefile
    def get_environment
      unless @environment.empty?
        env = @environment.map { |key, value| %Q[#{key}="#{value}"] }
        "export #{env.join(' ')}"
      else
        ":"
      end
    end
  end
end
