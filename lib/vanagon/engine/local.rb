require 'vanagon/engine/base'
require 'vanagon/utilities'
require 'vanagon/errors'

class Vanagon
  class Engine
    class Local < Base

      def initialize(platform, target = nil)
        @platform = platform
        @target = "local machine"
        @name = 'local'
        super
        @required_attributes = Array.new
      end

      # Dispatches the command for execution
      def dispatch(command, return_output = false)
        if defined?(Bundler)
          Bundler.with_clean_env do
            Vanagon::Utilities.local_command(command, return_command_output: return_output)
          end
        else
          Vanagon::Utilities.local_command(command, return_command_output: return_output)
        end
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
