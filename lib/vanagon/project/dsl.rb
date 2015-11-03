require 'vanagon/project'
require 'vanagon/utilities'
require 'vanagon/component/source'
require 'set'

class Vanagon
  class Project
    class DSL
      # Constructor for the DSL object
      #
      # @param name [String] name of the project
      # @param platform [Vanagon::Platform] platform for the project to build against
      # @param include_components [List] optional list restricting the loaded components
      # @return [Vanagon::Project::DSL] A DSL object to describe the {Vanagon::Project}
      def initialize(name, platform, include_components = [])
        @name = name
        @project = Vanagon::Project.new(@name, platform)
        @include_components = include_components.to_set
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

      # Resets the name of the project. Is useful for dynamically changing the project name.
      #
      # @param the_name [String] name of the project
      def name(the_name)
        @project.name = the_name
      end

      # Sets the homepage for the project. Mainly for use in packaging.
      #
      # @param page [String] url of homepage of the project
      def homepage(page)
        @project.homepage = page
      end

      # Sets the run time requirements for the project. Mainly for use in packaging.
      #
      # @param req [String] of requirements of the project
      def requires(req)
        @project.requires << req
      end

      # Indicates that this component replaces a system level package. Replaces can be collected and used by the project and package.
      #
      # @param replacement [String] a package that is replaced with this component
      # @param version [String] the version of the package that is replaced
      def replaces(replacement, version = nil)
        @project.replaces << OpenStruct.new(:replacement => replacement, :version => version)
      end

      # Indicates that this component provides a system level package. Provides can be collected and used by the project and package.
      #
      # @param provide [String] a package that is provided with this component
      # @param version [String] the version of the package that is provided with this component
      def provides(provide, version = nil)
        @project.provides << OpenStruct.new(:provide => provide, :version => version)
      end

      # Sets the version for the project. Mainly for use in packaging.
      #
      # @param ver [String] version of the project
      def version(ver)
        @project.version = ver.gsub('-', '.')
      end

      # Sets the release for the project. Mainly for use in packaging.
      #
      # @param rel [String] release of the project
      def release(rel)
        @project.release = rel
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
      # @param mode [String] octal mode to apply to the directory
      # @param owner [String] owner of the directory
      # @param group [String] group of the directory
      def directory(dir, mode: nil, owner: nil, group: nil)
        @project.directories << Vanagon::Common::Pathname.new(dir, mode: mode, owner: owner, group: group)
      end

      # Add a user to the project
      #
      # @param name [String] name of the user to create
      # @param group [String] group of the user
      # @param shell [String] login shell to set for the user
      # @param is_system [true, false] if the user should be a system user
      # @param homedir [String] home directory for the user
      def user(name, group: nil, shell: nil, is_system: false, homedir: nil)
        @project.user = Vanagon::Common::User.new(name, group, shell, is_system, homedir)
      end

      # Sets the license for the project. Mainly for use in packaging.
      #
      # @param lic [String] the license the project is released under
      def license(lic)
        @project.license = lic
      end

      # Sets the identifier for the project. Mainly for use in OSX packaging.
      #
      # @param ident [String] uses the reverse-domain naming convention
      def identifier(ident)
        @project.identifier = ident
      end

      # Adds a component to the project
      #
      # @param name [String] name of component to add. must be present in configdir/components and named $name.rb currently
      def component(name)
        puts "Loading #{name}"
        if @include_components.empty? or @include_components.include?(name)
          component = Vanagon::Component.load_component(name, File.join(Vanagon::Driver.configdir, "components"), @project.settings, @project.platform)
          @project.components << component
        end
      end

      # Adds a target repo for the project
      #
      # @param repo [String] name of the target repository to ship to used in laying out the packages on disk
      def target_repo(repo)
        @project.repo = repo
      end

      # Sets the project to be architecture independent, or noarch
      def noarch
        @project.noarch = true
      end

      # Sets up a rewrite rule for component sources for a given protocol
      #
      # @param protocol [String] a supported component source type (Http, Git, ...)
      # @param rule [String, Proc] a rule used to rewrite component source urls
      def register_rewrite_rule(protocol, rule)
        Vanagon::Component::Source.register_rewrite_rule(protocol, rule)
      end

      # Toggle to apply additional cleanup during the build for space constrained systems
      def cleanup_during_build
        @project.cleanup = true
      end

      # This method will write the project's version to a designated file during package creation
      # @param target [String] a full path to the version file for the project
      def write_version_file(target)
        @project.version_file = Vanagon::Common::Pathname.file(target)
      end

      # This method will write the project's bill-of-materials to a designated directory during package creation.
      # @param target [String] a full path to the directory for the bill-of-materials for the project
      def bill_of_materials(target)
        @project.bill_of_materials = Vanagon::Common::Pathname.new(target)
      end
    end
  end
end
