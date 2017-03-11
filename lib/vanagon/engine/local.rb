require 'vanagon/engine/base'
require 'vanagon/utilities'
require 'vanagon/errors'

class Vanagon
  class Engine
    class Local < Base
      def initialize(platform, target = nil, **opts)
        # local engine can't be used with a target
        super(platform, 'local machine')

        # We inherit a set of required attributes from Base,
        # and rather than instantiate a new empty array for
        # required attributes, we can just clear out the
        # existing ones.
        @required_attributes.clear
      end

      # Get the engine name
      def name
        'local'
      end

      # Return the target name to build on
      def build_host_name
        if @build_host_name.nil?
          validate_platform
          @build_host_name = @target
        end

        @build_host_name
      end

      # Dispatches the command for execution
      def dispatch(command, return_output = false)
        Vanagon::Utilities.local_command(command, return_command_output: return_output)
      end

      def ship_workdir(workdir)
        FileUtils.cp_r(Dir.glob("#{workdir}/*"), @remote_workdir)
      end

      def retrieve_built_artifact
        FileUtils.mkdir_p("output")
        FileUtils.cp_r(Dir.glob("#{@remote_workdir}/output/*"), "output/")
      end

      def retrieve_runtimes
        FileUtils.mkdir_p "runtimes"
        FileUtils.cp_r(
          Dir.glob("#{@remote_workdir}/runtimes/*",
          "runtimes/")
        )
      end
    end
  end
end
