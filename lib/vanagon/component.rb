require 'vanagon/component/source'
require 'vanagon/component/dsl'

class Vanagon
  class Component
    # @!attribute [r] files
    #   @return [Set] the list of files marked for installation

    attr_accessor :name, :version, :source, :url, :configure, :build, :install
    attr_accessor :environment, :extract_with, :dirname, :build_requires
    attr_accessor :settings, :platform, :patches, :requires, :service, :options
    attr_accessor :directories, :replaces, :provides, :cleanup_source, :environment
    attr_accessor :sources, :preinstall_actions, :postinstall_actions
    attr_accessor :preremove_actions, :postremove_actions

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
      dsl.instance_eval(code, __FILE__, __LINE__)
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
      @files = Set.new
      @directories = []
      @replaces = []
      @provides = []
      @environment = {}
      @sources = []
      @preinstall_actions = []
      @postinstall_actions = []
      @preremove_actions = []
      @postremove_actions = []
    end

    # Adds the given file to the list of files and returns @files.
    #
    # @param file [Vanagon::Common::Pathname] file to add to a component's list of files
    # @return [Set, nil] Returns @files if file is successfully added to @files
    #   or nil if file already exists
    def add_file(file)
      @files.add file
    end

    # Deletes the given file from the list of files and returns @files.
    #
    # @param file [String] path of file to delete from a component's list of files
    # @return [Set, nil] Returns @files if file is successfully deleted
    #   from @files or nil if file doesn't exist; this matches strictly on
    #   the path of a given file, and ignores other attributes like :mode,
    #   :owner, or :group.
    def delete_file(file)
      @files.delete_if { |this_file| this_file.path == file }
    end

    # Retrieve all items from @files not marked as configuration files
    #
    # @return [Set] all files not marked as configuration files
    def files
      @files.reject(&:configfile?)
    end

    # Retrieve all items from @files explicitly marked as configuration files
    #
    # @return [Set] all files explicitly marked as configuration files
    def configfiles
      @files.select(&:configfile?)
    end

    # Fetches the primary source for the component. As a side effect, also sets
    # \@extract_with, @dirname and @version for the component for use in the
    # makefile template
    #
    # @param workdir [String] working directory to put the source into
    def get_source(workdir)
      if @url
        @source = Vanagon::Component::Source.source(@url, @options, workdir)
        @source.fetch
        @source.verify
        @extract_with = @source.extract(@platform.tar) if @source.respond_to?(:extract)
        @cleanup_source = @source.cleanup if @source.respond_to?(:cleanup)
        @dirname = @source.dirname

        # Git based sources probably won't set the version, so we load it if it hasn't been already set
        @version ||= @source.version
      else
        warn "No source given for component '#{@name}'"

        # If there is no source, we don't want to try to change directories, so we just change to the current directory.
        @dirname = './'
      end
    end


    # Fetches secondary sources for the component. These are just dumped into the workdir currently.
    #
    # @param workdir [String] working directory to put the source into
    def get_sources(workdir)
      @sources.each do |source|
        cur_source = Vanagon::Component::Source.source(source.url, { :ref => source.ref, :sum => source.sum }, workdir)
        cur_source.fetch
        cur_source.verify
      end
    end

    # Fetches patches if any are provided for the project.
    #
    # @param workdir [String] working directory to put the patches into
    def get_patches(workdir)
      unless @patches.empty?
        patchdir = File.join(workdir, "patches")
        FileUtils.mkdir_p(patchdir)
        FileUtils.cp(@patches.map(&:path), patchdir)
      end
    end

    # Prints the environment in a way suitable for use in a Makefile
    # or shell script.
    #
    # @return [String] environment suitable for inclusion in a Makefile
    def get_environment
      if @environment.empty?
        ":"
      else
        env = @environment.map { |key, value| %(#{key}="#{value}") }
        "export #{env.join(' ')}"
      end
    end
  end
end
