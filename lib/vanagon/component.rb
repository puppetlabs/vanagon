require 'vanagon/component/dsl'
require 'vanagon/component/rules'
require 'vanagon/component/source'
require 'vanagon/component/source/rewrite'

class Vanagon
  class Component
    # @!attribute [r] files
    #   @return [Set] the list of files marked for installation

    # 30 accessors is too many. These have got to be refactored.
    # - Ryan McKern, 2017-01-27

    # The name, version, primary source, supplementary sources,
    # associated patches, upstream URL, and license of a given component
    attr_accessor :name
    attr_accessor :version
    attr_accessor :source
    attr_accessor :sources
    attr_accessor :patches
    attr_accessor :url
    attr_accessor :mirrors
    attr_accessor :license

    # holds an OpenStruct describing all of the particular details about
    # how any services associated with a given component should be defined.
    attr_accessor :service

    # holds the expected directory name of a given component, once it's
    # been unpacked/decompressed. For git repos, it's usually the directory
    # that they were cloned to. For the outlying flat files, it'll
    # end up being defined explicitly as the string './'
    attr_accessor :dirname
    # The specific tools or command line invocations that
    # should be used to extract a given component's sources
    attr_accessor :extract_with
    # how should this component be configured?
    attr_accessor :configure
    # the optional name of a directory to build a component in; most
    # likely to be used for cmake projects, which do not like to be
    # configured or compiled in their own top-level directories.
    attr_accessor :build_dir
    # build will hold an Array of the commands required to build
    # a given component
    attr_accessor :build
    # check will hold an Array of the commands required to validate/test
    # a given component
    attr_accessor :check
    # install will hold an Array of the commands required to install
    # a given component
    attr_accessor :install

    # holds a Vanagon::Environment object, to map out any desired
    # environment variables that should be rendered into the Makefile
    attr_accessor :environment
    # holds a OpenStruct, or an Array, or maybe it's a Hash? It's often
    # overloaded as a freeform key-value lookup for platforms that require
    # additional configuration beyond the "basic" component attributes.
    # it's pretty heavily overloaded and should maybe be refactored before
    # Vanagon 1.0.0 is tagged.
    attr_accessor :settings
    # used to hold the checksum settings or other weirdo metadata related
    # to building a given component (git ref, sha, etc.). Probably conflicts
    # or collides with #settings to some degree.
    attr_accessor :options
    # the platform that a given component will be built for -- due to the
    # fact that Ruby is pass-by-reference, it's usually just a reference
    # to the same Platform object that the overall Project object also
    # contains. This is a definite code smell, and should be slated
    # for refactoring ASAP because it's going to have weird side-effects
    # if the underlying pass-by-reference assumptions change.
    attr_accessor :platform

    # directories holds an Array with a list of expected directories that will
    # be packed into the resulting artifact's bill of materials.
    attr_accessor :directories
    # build_requires holds an Array with a list of the dependencies that a given
    # component needs satisfied before it can be built.
    attr_accessor :build_requires
    # requires holds an Array with a list of all dependencies that a given
    # component needs satisfied before it can be installed.
    attr_accessor :requires
    # replaces holds an Array of OpenStructs that describe a package that a given
    # component will replace on installation.
    attr_accessor :replaces
    # provides holds an Array of OpenStructs that describe any capabilities that
    # a given component will provide beyond the its filesystem payload.
    attr_accessor :provides
    # conflicts holds an Array of OpenStructs that describe a package that a
    # given component will replace on installation.
    attr_accessor :conflicts
    # preinstall_actions is a two-dimensional Array, describing scripts that
    # should be executed before a given component is installed.
    attr_accessor :preinstall_actions
    # install_triggers is a one-dimensional Array of OpenStructs, describing scripts that
    # should be executed when a package is installed or upgraded
    attr_accessor :install_triggers
    # interest_triggers is a one-dimensional Array of OpenStructs, describing scripts that
    # should be executed when a package identifies an interest trigger
    attr_accessor :interest_triggers
    # activate_triggers is a one-dimentional Array of Strings, describing scripts that
    # should be executed when a package identifies an activate trigger
    attr_accessor :activate_triggers
    # postinstall_actions is a two-dimensional Array, describing scripts that
    # should be executed after a given component is installed.
    attr_accessor :postinstall_actions
    # preremove_actions is a two-dimensional Array, describing scripts that
    # should be executed before a given component is uninstalled.
    attr_accessor :preremove_actions
    # preinstall_actions is a two-dimensional Array, describing scripts that
    # should be executed after a given component is uninstalled.
    attr_accessor :postremove_actions
    # cleanup_source contains whatever value a given component's Source has
    # specified as instructions for cleaning up after a build is completed.
    # usually a String, but not required to be.
    attr_accessor :cleanup_source

    # When dealing with compiled artifacts generated by setting
    # `project.generate_archives true`, you only need to install the component.
    # By setting install_only to true the component 'build' will exclude the
    # unpack, patch, configure, build, and check steps.
    attr_accessor :install_only

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
      dsl = Vanagon::Component::DSL.new(name, settings, platform)
      dsl.instance_eval(File.read(compfile), compfile, 1)
      dsl._component
    rescue => e
      $stderr.puts "Error loading project '#{name}' using '#{compfile}':"
      $stderr.puts e
      $stderr.puts e.backtrace.join("\n")
      raise e
    end

    # Component constructor.
    #
    # @param name [String] the name of the component
    # @param settings [Hash] the settings to be used in the component
    # @param platform [Vanagon::Platform] the platform to build the component for
    # @return [Vanagon::Component] the component with the given settings and platform
    def initialize(name, settings, platform) # rubocop:disable Metrics/AbcSize
      @name = name
      @settings = settings
      @platform = platform
      @options = {}
      @build_requires = []
      @requires = []
      @configure = []
      @install = []
      @build = []
      @check = []
      @patches = []
      @files = Set.new
      @directories = []
      @replaces = []
      @provides = []
      @conflicts = []
      @environment = Vanagon::Environment.new
      @sources = []
      @preinstall_actions = []
      @install_triggers = []
      @interest_triggers = []
      @activate_triggers = []
      @postinstall_actions = []
      @preremove_actions = []
      @postremove_actions = []
      @install_only = false
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

    # @return [Set] a list of unique mirror URIs that should be used to
    #   retrieve the upstream source before attempting to retrieve from
    #   whatever URI was defined for #uri.
    def mirrors
      @mirrors ||= Set.new [deprecated_rewrite_url].compact
    end

    # Retrieve upstream source file from a mirror, by randomly iterating
    # through #mirrors until there's no more mirrors left. Will #warn
    # if the mirror's URI cannot be resolved or if the URI cannot
    # be retrieved. Does not suppress any errors from
    # Vanagon::Component::Source.
    #
    # @return [Boolean] return True if the source can be retrieved,
    #   or False otherwise. This is because because each subclass of
    #   Vanagon::Component::Source returns an inconsistent value
    #   if #fetch is successful.
    def fetch_mirrors(options)
      mirrors.to_a.shuffle.each do |mirror|
        begin
          $stderr.puts %(Attempting to fetch from mirror URL "#{mirror}")
          @source = Vanagon::Component::Source.source(mirror, options)
          return true if source.fetch
        rescue SocketError
          # SocketError means that there was no DNS/name resolution
          # for whatever remote protocol the mirror tried to use.
          warn %(Unable to resolve mirror URL "#{mirror}")
        rescue RuntimeError
          # Source retrieval does not consistently return a meaningful
          # namespaced error message, which means we're brute-force rescuing
          # RuntimeError. Not a good look, and we should fix this.
          warn %(Unable to retrieve mirror URL "#{mirror}")
        end
      end
      false
    end

    # Retrieve upstream source file from the canonical URL.
    # Does not suppress any errors from Vanagon::Component::Source.
    #
    # @return [Boolean] return True if the source can be retrieved,
    #   or False otherwise
    def fetch_url(options)
      $stderr.puts %(Attempting to fetch from canonical URL "#{url}")
      @source = Vanagon::Component::Source.source(url, options)
      # Explicitly coerce the return value of #source.fetch,
      # because each subclass of Vanagon::Component::Source returns
      # an inconsistent value if #fetch is successful.
      !!source.fetch
    end

    # This method is deprecated and private. It will return
    # a rewritten URL if there's any value for #url.
    def deprecated_rewrite_url
      return nil unless url
      Vanagon::Component::Source::Rewrite.parse_and_rewrite(url)
    end
    private :deprecated_rewrite_url

    # Fetches the primary source for the component. As a side effect, also sets
    # @extract_with, @dirname and @version for the component for use in the
    # makefile template
    #
    # @param workdir [String] working directory to put the source into
    def get_source(workdir) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
      opts = options.merge({ workdir: workdir })
      if url || !mirrors.empty?
        fetch_mirrors(opts) || fetch_url(opts)
        source.verify
        extract_with << source.extract(platform.tar) if source.respond_to? :extract

        @cleanup_source = source.cleanup if source.respond_to?(:cleanup)
        @dirname ||= source.dirname

        # Git based sources probably won't set the version, so we load it if it hasn't been already set
        if source.respond_to?(:version)
          @version ||= source.version
        end
      else
        warn "No source given for component '#{@name}'"

        # If there is no source, we don't want to try to change directories, so we just change to the current directory.
        @dirname = './'

        # If there is no source, there is nothing to do to extract
        extract_with << ': no source, so nothing to extract'
      end
    end

    # Expands the build directory
    def get_build_dir
      if @build_dir
        File.join(@dirname, @build_dir)
      else
        @dirname
      end
    end

    def get_dependency_hash
      { name => { 'version' => version, 'url' => url, 'ref' => options[:ref] }.delete_if { |_, v| !v } }
    end

    # Fetches secondary sources for the component. These are just dumped into the workdir currently.
    #
    # @param workdir [String] working directory to put the source into
    def get_sources(workdir) # rubocop:disable Metrics/AbcSize
      sources.each do |source|
        src = Vanagon::Component::Source.source(
          source.url, workdir: workdir, ref: source.ref, sum: source.sum
        )
        src.fetch
        src.verify
        # set src.file to only be populated with the basename instead of entire file path
        src.file = File.basename(src.url)
        extract_with << src.extract(platform.tar) if src.respond_to? :extract
      end
    end

    # @return [Array] the specific tool or command line invocations that
    #   should be used to extract a given component's primary source
    def extract_with
      @extract_with ||= []
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
    # or shell script. This is deprecated, because all Env. Vars. are
    # moving directly into the Makefile (and out of recipe subshells).
    #
    # @return [String] environment suitable for inclusion in a Makefile
    # @deprecated
    def get_environment
      warn <<-eos.undent
        #get_environment is deprecated; environment variables have been moved
        into the Makefile, and should not be used within a Makefile's recipe.
        The #get_environment method will be removed by Vanagon 1.0.0.
      eos

      if environment.empty?
        ": no environment variables defined"
      else
        environment_variables
      end
    end

    def environment_variables
      environment.map { |key, value| %(export #{key}="#{value}") }
    end

    def rules(project, platform)
      Vanagon::Component::Rules.new(self, project, platform)
    end
  end
end
