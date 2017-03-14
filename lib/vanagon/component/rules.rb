require 'vanagon/component'
require 'vanagon/utilities/shell_utilities'
require 'makefile'

class Vanagon
  class Component
    # Vanagon::Component::Rules creates all Makefile rules for a given component.
    class Rules
      include Vanagon::Utilities::ShellUtilities

      # Create methods that generate Makefile rules.
      #
      # This method cuts out some of the boilerplate of creating Makefile rules
      # by creating methods and Makefile objects with a common name.
      #
      # @param target [Symbol] The rule target name.
      # @param dependencies [Array<String>] An optional list of dependencies for the rule
      # @yieldparam rule [Makefile::Rule] The generated Makefile rule
      # @return [void]
      #
      # @!macro [attach] rule
      #   @return [Makefile::Rule] The $1 rule
      def self.rule(target, &block)
        define_method("#{target}_rule") do
          Makefile::Rule.new("#{component.name}-#{target}") do |rule|
            instance_exec(rule, &block)
          end
        end
      end

      attr_accessor :component
      attr_accessor :project
      attr_accessor :platform

      # @param component [Vanagon::Component] The component to create rules for.
      # @param project [Vanagon::Project] The project associated with the component.
      # @param platform [Vanagon::Platform] The platform where this component will be built.
      def initialize(component, project, platform)
        @component = component
        @project = project
        @platform = platform
      end

      # Generate all Makefile rules for this component.
      #
      # If the project has the cleanup attribute set, a cleanup rule will be included
      # in the returned rules.
      #
      # @return [Array<Makefile::Rule>]
      def rules
        list = [
          component_rule,
          unpack_rule,
          patch_rule,
          configure_rule,
          build_rule,
          check_rule,
          install_rule,
          clean_rule,
          clobber_rule,
        ]
        if project.cleanup
          list << cleanup_rule
        end

        list
      end

      # Generate a top level rule to build this component.
      #
      # @return [Makefile::Rule]
      def component_rule
        Makefile::Rule.new(component.name) do |rule|
          rule.dependencies = ["#{component.name}-install"]
        end
      end

      # Unpack the source for this component. The unpacking behavior depends on
      # the source type of the component.
      #
      # @see [Vanagon::Component::Source]
      rule("unpack") do |r|
        r.dependencies = ['file-list-before-build']
        r.recipe << andand_multiline(component.environment_variables, component.extract_with)
        r.recipe << "touch #{r.target}"
      end

      # Apply any patches for this component.
      rule("patch") do |r|
        r.dependencies = ["#{component.name}-unpack"]
        after_unpack_patches = component.patches.select { |patch| patch.after == "unpack" }
        unless after_unpack_patches.empty?
          r.recipe << andand_multiline(
            "cd #{component.dirname}",
            after_unpack_patches.map { |patch| patch.cmd(platform) }
          )
        end

        r.recipe << "touch #{r.target}"
      end

      # Create a build directory for this component if an out of source tree build is specified,
      # and any configure steps, if any.
      rule("configure") do |r|
        r.dependencies = ["#{component.name}-patch"].concat(project.list_component_dependencies(component))
        if component.get_build_dir
          r.recipe << "[ -d #{component.get_build_dir} ] || mkdir -p #{component.get_build_dir}"
        end

        unless component.configure.empty?
          r.recipe << andand_multiline(
            component.environment_variables,
            "cd #{component.get_build_dir}",
            component.configure
          )
        end

        r.recipe << "touch #{r.target}"
      end

      # Build this component.
      rule("build") do |r|
        r.dependencies = ["#{component.name}-configure"]
        unless component.build.empty?
          r.recipe << andand_multiline(
            component.environment_variables,
            "cd #{component.get_build_dir}",
            component.build
          )
        end

        r.recipe << "touch #{r.target}"
      end

      # Run tests for this component.
      rule("check") do |r|
        r.dependencies = ["#{component.name}-build"]
        unless component.check.empty? || project.settings[:skipcheck]
          r.recipe << andand_multiline(
            component.environment_variables,
            "cd #{component.get_build_dir}",
            component.check
          )
        end

        r.recipe << "touch #{r.target}"
      end

      # Install this component.
      rule("install") do |r|
        r.dependencies = ["#{component.name}-check"]
        unless component.install.empty?
          r.recipe << andand_multiline(
            component.environment_variables,
            "cd #{component.get_build_dir}",
            component.install
          )
        end

        after_install_patches = component.patches.select { |patch| patch.after == "install" }
        after_install_patches.each do |patch|
          r.recipe << andand(
            "cd #{patch.destination}",
            patch.cmd(platform),
          )
        end

        r.recipe << "touch #{r.target}"
      end

      # Run any post-installation cleanup steps for this component.
      #
      # This component is only included by {#rules} if the associated project has
      # the `cleanup` attribute set.
      rule("cleanup") do |r|
        r.dependencies = ["#{component.name}-install"]
        r.recipe = [component.cleanup_source, "touch #{r.target}"]
      end

      # Clean up any files generated while building this project.
      #
      # This cleans up the project by invoking `make clean` and removing the touch files
      # for the configure/build/install steps.
      rule("clean") do |r|
        r.recipe << andand(
          "[ -d #{component.get_build_dir} ]",
          "cd #{component.get_build_dir}",
          "#{platform[:make]} clean"
        )

        %w(configure build install).each do |type|
          touchfile = "#{component.name}-#{type}"
          r.recipe << andand(
            "[ -e #{touchfile} ]",
            "rm #{touchfile}"
          )
        end
      end

      # Remove all files associated with this component.
      rule("clobber") do |r|
        r.dependencies = ["#{component.name}-clean"]
        r.recipe = [
          andand("[ -d #{component.dirname} ]", "rm -r #{component.dirname}"),
          andand("[ -e #{component.name}-unpack ]", "rm #{component.name}-unpack")
        ]
      end

      # Generate a Makefile fragment that contains all of the rules for the component.
      # @return [String]
      def format
        rules.map(&:to_s).join("\n")
      end

      alias to_s format
    end
  end
end
