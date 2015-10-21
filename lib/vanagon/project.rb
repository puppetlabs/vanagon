require 'vanagon/component'
require 'vanagon/platform'
require 'vanagon/project/dsl'
require 'vanagon/utilities'
require 'ostruct'

class Vanagon
  class Project
    include Vanagon::Utilities
    attr_accessor :components, :settings, :platform, :configdir, :name
    attr_accessor :version, :directories, :license, :description, :vendor
    attr_accessor :homepage, :requires, :user, :repo, :noarch, :identifier
    attr_accessor :cleanup, :version_file, :release, :replaces, :provides

    # Loads a given project from the configdir
    #
    # @param name [String] the name of the project
    # @param configdir [String] the path to the project config file
    # @param platform [Vanagon::Platform] platform to build against
    # @param include_components [List] optional list restricting the loaded components
    # @return [Vanagon::Project] the project as specified in the project config
    # @raise if the instance_eval on Project fails, the exception is reraised
    def self.load_project(name, configdir, platform, include_components = [])
      projfile = File.join(configdir, "#{name}.rb")
      code = File.read(projfile)
      dsl = Vanagon::Project::DSL.new(name, platform, include_components)
      dsl.instance_eval(code, __FILE__, __LINE__)
      dsl._project
    rescue => e
      puts "Error loading project '#{name}' using '#{projfile}':"
      puts e
      puts e.backtrace.join("\n")
      raise e
    end

    # Project constructor. Takes just the name. Also sets the @name and
    # @platform, and initializes @components, @directories and @settings.
    #
    # @param name [String] name of the project
    # @param platform [Vanagon::Platform] platform for the project to be built for
    # @return [Vanagon::Project] the project with the given name and platform
    def initialize(name, platform)
      @name = name
      @components = []
      @requires = []
      @directories = []
      @settings = {}
      @platform = platform
      @release = "1"
      @replaces = []
      @provides = []
    end

    # Magic getter to retrieve settings in the project
    def method_missing(method, *args)
      if @settings.has_key?(method)
        return @settings[method]
      end
    end

    # Collects all sources and patches into the provided workdir
    #
    # @param workdir [String] directory to stage sources into
    def fetch_sources(workdir)
      @components.each do |component|
        component.get_source(workdir)
        # Fetch secondary sources
        component.get_sources(workdir)
        component.get_patches(workdir)
      end
    end

    # Collects any additional files supplied by components
    #
    # @return [Array] array of files installed by components of the project
    def get_files
      files = []
      files.push @version_file if @version_file
      files.push @components.map(&:files).flatten
      files.flatten.uniq
    end

    # Collects all of the requires for both the project and its components
    #
    # @return [Array] array of runtime requirements for the project
    def get_requires
      req = []
      req << @components.map(&:requires).flatten
      req << @requires
      req.flatten.uniq
    end

    # Collects all of the replacements for the project and its components
    #
    # @return [Array] array of package level replacements for the project
    def get_replaces
      replaces = []
      replaces.push @replaces.flatten
      replaces.push @components.map(&:replaces).flatten
      replaces.flatten.uniq
    end

    # Collects all of the provides for the project and its components
    #
    # @return [Array] array of package level provides for the project
    def get_provides
      provides = []
      provides.push @provides.flatten
      provides.push @components.map(&:provides).flatten
      provides.flatten.uniq
    end

    # Collects the preinstall packaging actions for the project and it's components
    # for the specified packaging state
    #
    # @param pkg_state [String] the package state we want to run the given scripts for.
    #   Can be one or more of 'install' or 'upgrade'
    # @return [Array] array of Bourne shell compatible scriptlets to execute during the preinstall
    #   phase of packaging during the state of the system defined by pkg_state (either install or upgrade)
    def get_preinstall_actions(pkg_state)
      scripts = []
      @components.map(&:preinstall_actions).flatten.compact.select { |s| s.pkg_state.include? pkg_state }.each do |action|
        scripts << action.scripts
      end
      scripts
    end


    # Collects the postinstall packaging actions for the project and it's components
    # for the specified packaging state
    #
    # @param pkg_state [String] the package state we want to run the given scripts for.
    #   Can be one or more of 'install' or 'upgrade'
    # @return [Array] array of Bourne shell compatible scriptlets to execute during the postinstall
    #   phase of packaging during the state of the system defined by pkg_state (either install or upgrade)
    def get_postinstall_actions(pkg_state)
      scripts = []
      @components.map(&:postinstall_actions).flatten.compact.select { |s| s.pkg_state.include? pkg_state }.each do |action|
        scripts << action.scripts
      end
      scripts
    end

    # Collects the preremove packaging actions for the project and it's components
    # for the specified packaging state
    #
    # @param pkg_state [String] the package state we want to run the given scripts for.
    #   Can be one or more of 'removal' or 'upgrade'
    # @return [Array] array of Bourne shell compatible scriptlets to execute during the preremove
    #   phase of packaging during the state of the system defined by pkg_state (either removal or upgrade)
    def get_preremove_actions(pkg_state)
      scripts = []
      @components.map(&:preremove_actions).flatten.compact.select { |s| s.pkg_state.include? pkg_state }.each do |action|
        scripts << action.scripts
      end
      scripts
    end

    # Collects the postremove packaging actions for the project and it's components
    # for the specified packaging state
    #
    # @param pkg_state [String] the package state we want to run the given scripts for.
    #   Can be one or more of 'removal' or 'upgrade'
    # @return [Array] array of Bourne shell compatible scriptlets to execute during the postremove
    #   phase of packaging during the state of the system defined by pkg_state (either removal or upgrade)
    def get_postremove_actions(pkg_state)
      scripts = []
      @components.map(&:postremove_actions).flatten.compact.select { |s| s.pkg_state.include? pkg_state }.each do |action|
        scripts << action.scripts
      end
      scripts
    end

    # Collects any configfiles supplied by components
    #
    # @return [Array] array of configfiles installed by components of the project
    def get_configfiles
      @components.map(&:configfiles).flatten.uniq
    end

    # Collects any directories declared by the project and components
    #
    # @return [Array] the directories in the project and components
    def get_directories
      dirs = []
      dirs.push @directories
      dirs.push @components.map(&:directories).flatten
      dirs.flatten.uniq
    end

    # Gets the highest level directories declared by the project
    #
    # @return [Array] the highest level directories that have been declared by the project
    def get_root_directories
      dirs = get_directories.map { |dir| dir.path.split('/') }
      dirs.sort! { |dir1, dir2| dir1.length <=> dir2.length }
      ret_dirs = []

      dirs.each do |dir|
        unless ret_dirs.include?(dir.first(dir.length - 1).join('/'))
          ret_dirs << dir.join('/')
        end
      end
      ret_dirs
    end

    # Get any services registered by components in the project
    #
    # @return [Array] the services provided by components in the project
    def get_services
      @components.map(&:service).flatten.compact
    end

    # Simple utility for determining if the components in the project declare
    # any services
    #
    # @return [True, False] Whether or not there are services declared for this project or not
    def has_services?
      !get_services.empty?
    end

    # Generate a list of all files and directories to be included in a tarball
    # for the project
    #
    # @return [Array] all the files and directories that should be included in the tarball
    def get_tarball_files
      files = ['file-list', 'bill-of-materials']
      files.push get_files.map(&:path)
      files.push get_configfiles.map(&:path)
    end

    # Generate a bill-of-materials: a listing of the components and their
    # versions in the current project
    #
    # @return [Array] a listing of component names and versions
    def generate_bill_of_materials
      @components.map { |comp| "#{comp.name} #{comp.version}" }.sort
    end

    # Method to generate the command to create a tarball of the project
    #
    # @return [String] cross platform command to generate a tarball of the project
    def pack_tarball_command
      tar_root = "#{@name}-#{@version}"
      ["mkdir -p '#{tar_root}'",
       %('#{@platform.tar}' -cf - -T #{get_tarball_files.join(" ")} | ( cd '#{tar_root}/'; '#{@platform.tar}' xfp -)),
       %('#{@platform.tar}' -cf - #{tar_root}/ | gzip -9c > #{tar_root}.tar.gz)].join("\n\t")
    end

    # Evaluates the makefile template and writes the contents to the workdir
    # for use in building the project
    #
    # @param workdir [String] full path to the workdir to send the evaluated template
    # @return [String] full path to the generated Makefile
    def make_makefile(workdir)
      erb_file(File.join(VANAGON_ROOT, "templates/Makefile.erb"), File.join(workdir, "Makefile"))
    end

    # Generates a bill-of-materials and writes the contents to the workdir for use in
    # building the project
    #
    # @param workdir [String] full path to the workdir to send the bill-of-materials
    # @return [String] full path to the generated bill-of-materials
    def make_bill_of_materials(workdir)
      File.open(File.join(workdir, 'bill-of-materials'), 'w') { |f| f.puts(generate_bill_of_materials.join("\n")) }
    end

    # Return a list of the build_dependencies that are satisfied by an internal component
    #
    # @param component [Vanagon::Component] component to check for already satisfied build dependencies
    # @return [Array] a list of the build dependencies for the given component that are satisfied by other components in the project
    def list_component_dependencies(component)
      component.build_requires.select { |dep| @components.map(&:name).include?(dep) }
    end

    # Get the package name for the project on the current platform
    #
    # @return [String] package name for the current project as defined by the platform
    def package_name
      @platform.package_name(self)
    end

    # Ascertain how to build a package for the current platform
    #
    # @return [String, Array] commands to build a package for the current project as defined by the platform
    def generate_package
      @platform.generate_package(self)
    end

    # Generate any required files to build a package for this project on the
    # current platform into the provided workdir
    #
    # @param workdir [String] workdir to put the packaging files into
    def generate_packaging_artifacts(workdir)
      @platform.generate_packaging_artifacts(workdir, @name, binding)
    end
  end
end
