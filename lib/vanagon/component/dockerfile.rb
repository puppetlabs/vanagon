require 'vanagon/component'
require 'vanagon/utilities/shell_utilities'

class Vanagon
  class Component
    # Vanagon::Component::Dockerfile generates the Dockerfile contents for
    # a given component.
    #
    # TODO: This class + the corresponding Component::Rules class have a similar
    # structure, specifically in how they calculate the required commands that will
    # need to run for a given step. That calculation logic should be factored out into
    # a common module. Note that it is for precisely this reason that the individual
    # "step" methods are essentially copy-pastes of the corresponding "rule" methods
    # in Vanagon::Component::Rules.
    class Dockerfile
      include Vanagon::Utilities::ShellUtilities

      # Create methods that generate the Dockerfile contents for a specific
      # step when building the component.
      #
      # This method cuts some of the boilerplate command munging + Dockerfile
      # generation for each step.
      #
      # The block should return an array of commands that will be run for a given
      # step.
      #
      # @param step_name [String] The step's name
      def self.step(step_name, &block)
        define_method("#{step_name}_step") do
          commands = instance_exec(&block)
          commands.flatten!
          commands.compact!
          commands.reject!(&:empty?)
          commands = andand_multiline(commands)

          next "" if commands.empty?

          <<-DOCKERFILE.undent
  # #{component.name}-#{step_name}
  RUN #{commands}
          DOCKERFILE
        end
      end

      attr_accessor :component
      attr_accessor :project
      attr_accessor :platform

      # @param component [Vanagon::Component] The component to generate the Dockerfile for.
      # @param project [Vanagon::Project] The project associated with the component.
      # @param platform [Vanagon::Platform] The platform where this component will be built.
      def initialize(component, project, platform)
        @component = component
        @project = project
        @platform = platform
      end

      # This override of andand_multiline is purely for aesthetic purposes, i.e. it makes
      # the generated Dockerfile more readable.
      def andand_multiline(*commands)
        cmdjoin(commands, " && \\\n    ")
      end

      # Generate the component's Dockerfile
      #
      # @return [String] the contents of the component's Dockerfile.
      def generate
        steps = [
          create_directories_step(),
          copy_sources_step(),
          unpack_step(),
          patch_step(),
          configure_step(),
          build_step(),
          check_step(),
          install_step(),
        ]

        if component.install_only
          steps = [
            create_directories_step(),
            copy_sources_step(),
            install_step(),
          ]
        end

        steps.join("\n")
      end

      # Create the component's directories
      def create_directories_step
        create_directories_cmd = component.directories.map(&:path).map do |dir|
          "mkdir -p #{dir}"
        end

        return "" if create_directories_cmd.empty?

        <<-DOCKERFILE.undent
  # #{component.name}-create-directories
  RUN #{andand_multiline(create_directories_cmd)}
        DOCKERFILE
      end

      # Copy the component's sources.
      def copy_sources_step
        <<-DOCKERFILE.undent
  # #{component.name}-copy-sources
  COPY #{component.name}_sources ${workdir}
  #{"COPY #{component.name}_sources/patches ${workdir}/patches" unless component.patches.empty?}
        DOCKERFILE
      end

      # Unpack the source for this component. The unpacking behavior depends on
      # the source type of the component.
      #
      # @see [Vanagon::Component::Source]
      step("unpack") do
        [
          andand_multiline(component.environment_variables, component.extract_with)
        ]
      end

      # Apply any patches for this component.
      step("patch") do
        commands = []

        after_unpack_patches = component.patches.select { |patch| patch.after == "unpack" }
        unless after_unpack_patches.empty?
          commands << andand_multiline(
            "cd #{component.dirname}",
            after_unpack_patches.map { |patch| patch.cmd(platform) }
          )
        end

        commands
      end

      # Create a build directory for this component if an out of source tree build is specified,
      # and any configure steps, if any.
      step("configure") do
        commands = []
        if component.get_build_dir
          commands << "[ -d #{component.get_build_dir} ] || mkdir -p #{component.get_build_dir}"
        end

        unless component.configure.empty?
          commands << andand_multiline(
            component.environment_variables,
            "cd #{component.get_build_dir}",
            component.configure
          )
        end

        commands
      end

      # Build this component.
      step("build") do
        commands = []
        unless component.build.empty?
          commands << andand_multiline(
            component.environment_variables,
            "cd #{component.get_build_dir}",
            component.build
          )
        end

        commands
      end

      # Run tests for this component.
      step("check") do
        commands = []
        unless component.check.empty? || project.settings[:skipcheck]
          commands << andand_multiline(
            component.environment_variables,
            "cd #{component.get_build_dir}",
            component.check
          )
        end

        commands
      end

      # Install this component.
      step("install") do
        commands = []
        unless component.install.empty?
          if component.install_only
            commands << andand_multiline(
              component.environment_variables,
              component.install
            )
          else
            commands << andand_multiline(
              component.environment_variables,
              "cd #{component.get_build_dir}",
              component.install
            )
          end
        end

        after_install_patches = component.patches.select { |patch| patch.after == "install" }
        after_install_patches.each do |patch|
          commands << andand(
            "cd #{patch.destination}",
            patch.cmd(platform),
          )
        end

        commands
      end
    end
  end
end
