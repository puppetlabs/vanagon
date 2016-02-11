require 'vanagon/engine/base'
require 'vanagon/utilities'
require 'vanagon/errors'

class Vanagon
  class Engine
    class Local < Base

      def initialize(platform, target = nil)
        @target = target || "local machine"
        @name = 'local'
        super

        # We inherit a set of required attributes from Base,
        # and rather than instantiate a new empty array for
        # required attributes, we can just clear out the
        # existing ones.
        @required_attributes.clear
      end

      # Dispatches the command for execution
      def dispatch(command, return_output = false)
        Vanagon::Utilities.local_command(command, return_command_output: return_output)
      end

      def ship_workdir(workdir)
        FileUtils.cp_r(Dir.glob("#{workdir}/*"), "#{@remote_workdir}")
      end

      def retrieve_built_artifact
        FileUtils.mkdir_p("output")
        FileUtils.cp_r(Dir.glob("#{@remote_workdir}/output/*"), "output/")
      end
    end
  end
end
