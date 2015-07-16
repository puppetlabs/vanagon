require 'vanagon/utilities'
require 'vanagon/errors'
require 'benchmark'

class Vanagon
  class Engine
    class Local
      attr_accessor :target

      def initialize(platform, target = nil)
        @platform = platform
        @target = "local machine"
      end

      # Dispatches the command for execution
      def dispatch(command)
        puts Benchmark.measure { local_command(command, @workdir) }
      end

      # Steps needed to tear down or clean up the system after the build is
      # complete
      def teardown
      end

      # This method will take care of validation and target selection all at
      # once as an easy shorthand to call from the driver
      def startup(workdir)
        @workdir = workdir
        script = @platform.provisioning.join(' && ')
        dispatch(script)
      end

      def ship_workdir(workdir)
      end

      def retrieve_built_artifact
      end
    end
  end
end
