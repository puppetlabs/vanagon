require 'vanagon/engine/base'

class Vanagon
  class Engine
    class Docker < Base
      # Both the docker_image and the docker command itself are required for
      # the docker engine to work
      def initialize(platform, target = nil, opts = {})
        super

        @docker_cmd = Vanagon::Utilities.find_program_on_path('docker')
        @required_attributes << "docker_image"
      end

      # Get the engine name
      def name
        'docker'
      end

      # Return the docker image name to build on
      def build_host_name
        if @build_host_name.nil?
          validate_platform
          @build_host_name = @platform.docker_image
        end

        @build_host_name
      end

      # This method is used to obtain a vm to build upon using
      # a docker container.
      # @raise [Vanagon::Error] if a target cannot be obtained
      def select_target
        Vanagon::Utilities.ex("#{@docker_cmd} run -d --name #{build_host_name}-builder -p #{@platform.ssh_port}:22 #{build_host_name}")
        @target = 'localhost'

        # Wait for ssh to come up in the container
        Vanagon::Utilities.retry_with_timeout do
          Vanagon::Utilities.remote_ssh_command("#{@target_user}@#{@target}", 'exit', @platform.ssh_port)
        end
      rescue => e
        raise Vanagon::Error.wrap(e, "Something went wrong getting a target vm to build on using docker. Ssh was not up in the container after 5 seconds.")
      end

      # This method is used to tell the vmpooler to delete the instance of the
      # vm that was being used so the pool can be replenished.
      def teardown
        Vanagon::Utilities.ex("#{@docker_cmd} stop #{build_host_name}-builder")
        Vanagon::Utilities.ex("#{@docker_cmd} rm #{build_host_name}-builder")
      rescue Vanagon::Error => e
        warn "There was a problem tearing down the docker container #{build_host_name}-builder (#{e.message})."
      end
    end
  end
end

