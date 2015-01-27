require 'vanagon/component'
require 'vanagon/platform'
require 'vanagon/project/dsl'
require 'vanagon/utilities'
require 'ostruct'

class Vanagon
  class Project
    include Vanagon::Utilities
    attr_accessor :components, :settings, :platform, :configdir, :name, :version, :directories, :license, :description, :vendor, :homepage, :requires

    # Loads a given project from the configdir
    #
    # @param name [String] the name of the project
    # @param configdir [String] the path to the project config file
    # @param platform [Vanagon::Platform] platform to build against
    # @return [Vanagon::Project] the project as specified in the project config
    # @raise if the instance_eval on Project fails, the exception is reraised
    def self.load_project(name, configdir, platform)
      projfile = File.join(configdir, "#{name}.rb")
      code = File.read(projfile)
      dsl = Vanagon::Project::DSL.new(name, platform)
      dsl.instance_eval(code)
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
        unless component.patches.empty?
          patchdir = File.join(workdir, "patches")
          FileUtils.mkdir_p(patchdir)
          FileUtils.cp(component.patches, patchdir)
        end
      end
    end

    # Collects any additional files supplied by components
    #
    # @return [Array] array of files installed by components of the project
    def get_files
      @components.map {|comp| comp.files }.flatten
    end

    def get_requires
      req = []
      req << @components.map {|comp| comp.requires }.flatten
      req << @requires
      req.flatten.uniq
    end

    # Collects any configfiles supplied by components
    #
    # @return [Array] array of configfiles installed by components of the project
    def get_configfiles
      @components.map {|comp| comp.configfiles }.flatten
    end

    # This method may eventually include collecting directories from
    # components, if components are allowed to register directories.
    #
    # @return [Array] the directories in the project
    def get_directories
      @directories
    end

    # Get any services registered by components in the project
    #
    # @return [Array] the services provided by components in the project
    def get_services
      @components.map {|comp| comp.service }.flatten.compact
    end

    # Simple utility for determining if the components in the project declare
    # any services
    #
    # @return [True, False] Whether or not there are services declared for this project or not
    def has_services?
      ! get_services.empty?
    end

    # Generate a list of all files and directories to be included in a tarball
    # for the project
    #
    # @return [Array] all the files and directories that should be included in the tarball
    def get_tarball_files
      files = []
      files.push get_directories
      files.push get_files
    end

    # Method to generate the command to create a tarball of the project
    #
    # @return [String] cross platform command to generate a tarball of the project
    def pack_tarball_command
      tar_root = "#{@name}-#{@version}"
      ["mkdir -p '#{tar_root}'",
       %Q[tar -cf - #{get_tarball_files.join(" ")} | ( cd '#{tar_root}/'; tar xfp -)],
       %Q[tar -cf - #{tar_root}/ | gzip -9c > #{tar_root}.tar.gz]].join("\n\t")
    end

    # Evaluates the makefile template and writes the contents to the workdir
    # for use in building the project
    #
    # @return [String] full path to the generated Makefile
    def make_makefile(workdir)
      erb_file(File.join(VANAGON_ROOT, "templates/Makefile.erb"), File.join(workdir, "Makefile"))
    end

    # Return a list of the build_dependencies that are satisfied by an internal component
    #
    # @param component [Vanagon::Component] component to check for already satisfied build dependencies
    # @return [Array] a list of the build dependencies for the given component that are satisfied by other components in the project
    def list_component_dependencies(component)
      component.build_requires.select {|dep| @components.map {|comp| comp.name}.include?(dep) }
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
