require 'vanagon/project'
require 'vanagon/utilities'

class Vanagon
  class Project
    class DSL
      # Constructor for the DSL object
      #
      # @param name [String] name of the project
      # @param platform [Vanagon::Platform] platform for the project to build against
      # @return [Vanagon::Project::DSL] A DSL object to describe the {Vanagon::Project}
      def initialize(name, platform)
        @name = name
        @project = Vanagon::Project.new(@name, platform)
      end

      # Primary way of interacting with the DSL
      #
      # @param name [String] name of the project
      # @param block [Proc] DSL definition of the project to call
      def project(name, &block)
        block.call(self)
      end

      # Accessor for the project.
      #
      # @return [Vanagon::Project] the project the DSL methods will be acting against
      def _project
        @project
      end


      # Project attributes and DSL methods defined below
      #
      #
      # All purpose getter. This object, which is passed to the project block,
      # won't have easy access to the attributes of the @project, so we make a
      # getter for each attribute.
      #
      # We only magically handle get_ methods, any other methods just get the
      # standard method_missing treatment.
      #
      def method_missing(method, *args)
        attribute_match = method.to_s.match(/get_(.*)/)
        if attribute_match
          attribute = attribute_match.captures.first
          @project.send(attribute)
        elsif @project.settings.has_key?(method)
          return @project.settings[method]
        else
          super
        end
      end

      # Sets a key value pair on the settings hash of the project
      #
      # @param name [String] name of the setting
      # @param value [String] value of the setting
      def setting(name, value)
        @project.settings[name] = value
      end

      # Sets the description of the project. Mainly for use in packaging.
      #
      # @param descr [String] description of the project
      def description(descr)
        @project.description = descr
      end

      # Sets the homepage for the project. Mainly for use in packaging.
      #
      # @param page [String] url of homepage of the project
      def homepage(page)
        @project.homepage = page
      end

      # Sets the version for the project. Mainly for use in packaging.
      #
      # @param ver [String] version of the project
      def version(ver)
        @project.version = ver
      end

      # Sets the version for the project based on a git describe of the
      # directory that holds the configs. Requires that a git tag be present
      # and reachable from the current commit in that repository.
      #
      def version_from_git
        @project.version = Vanagon::Utilities.git_version(File.expand_path("..", Vanagon::Driver.configdir)).gsub('-', '.')
      end

      # Sets the vendor for the project. Used in packaging artifacts.
      #
      # @param vend [String] vendor or author of the project
      def vendor(vend)
        @project.vendor = vend
      end

      # Adds a directory to the list of directories provided by the project, to be included in any packages of the project
      #
      # @param dir [String] directory to add to the project
      def directory(dir)
        @project.directories << dir
      end

      # Sets the license for the project. Mainly for use in packaging.
      #
      # @param lic [String] the license the project is released under
      def license(lic)
        @project.license = lic
      end

      # Adds a component to the project
      #
      # @param name [String] name of component to add. must be present in configdir/components and named $name.rb currently
      def component(name)
        puts "Loading #{name}"
        component = Vanagon::Component.load_component(name, File.join(Vanagon::Driver.configdir, "components"), @project.settings, @project.platform)
        @project.components << component if component.url
      end
    end
  end
end
