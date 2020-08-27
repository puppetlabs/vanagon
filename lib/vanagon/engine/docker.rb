require 'vanagon/engine/base'

class Vanagon
  class Engine
    class Docker < Base
      # Both the docker_image and the docker command itself are required for
      # the docker engine to work
      def initialize(platform, target = nil, **opts)
        super

        @docker_cmd = Vanagon::Utilities.find_program_on_path('docker')
        @required_attributes << "docker_image"
        @required_attributes.delete('ssh_port') if @platform.use_docker_exec
      end

      # Get the engine name
      def name
        'docker'
      end

      # Return the docker image name to build on
      def build_host_name
        if @build_host_name.nil?
          validate_platform
          # Docker requires container names to match: [a-zA-Z0-9][a-zA-Z0-9_.-]
          # So, transform slashes and colons commonly used as separators in
          # image names.
          @build_host_name = @platform.docker_image.gsub(%r{[/:]}, '_')
        end

        @build_host_name
      end

      # This method is used to obtain a vm to build upon using
      # a docker container.
      # @raise [Vanagon::Error] if a target cannot be obtained
      def select_target
        ssh_args = @platform.use_docker_exec ? '' : "-p #{@platform.ssh_port}:22"
        extra_args = @platform.docker_run_args.nil? ? [] : @platform.docker_run_args

        Vanagon::Utilities.ex("#{@docker_cmd} run -d --name #{build_host_name}-builder #{ssh_args} #{extra_args.join(' ')} #{@platform.docker_image}")
        @target = 'localhost'

        wait_for_ssh unless @platform.use_docker_exec
      rescue StandardError => e
        raise Vanagon::Error.wrap(e, "Something went wrong getting a target vm to build on using Docker.")
      end

      # This method is used to tell the vmpooler to delete the instance of the
      # vm that was being used so the pool can be replenished.
      def teardown
        Vanagon::Utilities.ex("#{@docker_cmd} stop #{build_host_name}-builder")
        Vanagon::Utilities.ex("#{@docker_cmd} rm #{build_host_name}-builder")
      rescue Vanagon::Error => e
        warn "There was a problem tearing down the docker container #{build_host_name}-builder (#{e.message})."
      end

      def dispatch(command, return_output = false)
        if @platform.use_docker_exec
          docker_exec(command, return_output)
        else
          super
        end
      end

      def ship_workdir(workdir)
        if @platform.use_docker_exec
          docker_cp_globs_to("#{workdir}/*", @remote_workdir)
        else
          super
        end
      end

      def retrieve_built_artifact(artifacts_to_fetch, no_packaging)
        if @platform.use_docker_exec
          output_path = 'output/'
          FileUtils.mkdir_p(output_path)
          unless no_packaging
            artifacts_to_fetch << "#{@remote_workdir}/output/*"
          end

          docker_cp_globs_from(artifacts_to_fetch, 'output/')
        else
          super
        end
      end

      # Execute a command on a container via docker exec
      def docker_exec(command, return_output = false)
        command = command.gsub("'", "'\\\\''")
        Vanagon::Utilities.local_command("#{@docker_cmd} exec #{build_host_name}-builder /bin/sh -c '#{command}'",
                                         return_command_output: return_output)
      end

      # Copy files between a container and the host
      def docker_cp(source, target)
        Vanagon::Utilities.ex("#{@docker_cmd} cp '#{source}' '#{target}'")
      end

      # Copy files matching a glob pattern from the host to the container
      def docker_cp_globs_to(globs, container_path)
        Array(globs).each do |glob|
          Dir.glob(glob).each do |path|
            docker_cp(path, "#{build_host_name}-builder:#{container_path}")
          end
        end
      end

      # Copy files matching a glob pattern from the container to the host
      #
      # @note Globs are expanded by running `/bin/sh` in the container, which
      #   may not support the same variety of expressions as Ruby's `Dir.glob`.
      #   For example, `**` may not work.
      def docker_cp_globs_from(globs, host_path)
        Array(globs).each do |glob|
          # Match the behavior of `rsync -r` when both paths are directories
          # by copying the contents of the directory instead of the directory.
          glob += '*' if glob.end_with?('/') && host_path.end_with?('/')

          # TODO: This doesn't handle "interesting" paths. E.g. paths with
          #   spaces or other special non-glob characters. This could be
          #   fixed with a variant of `Shellwords.shellescape` that allows
          #   glob characters to pass through.
          paths = docker_exec(%(for file in #{glob};do [ -e "$file" ] && printf '%s\\0' "${file}";done), true).split("\0")

          paths.each do |path|
            docker_cp("#{build_host_name}-builder:#{path}", host_path)
          end
        end
      end

      # Wait for ssh to come up in the container
      #
      # Retry 5 times with a 1 second sleep between errors to account for
      # network resets while SSHD is starting. Allow a maximum of 5 seconds for
      # SSHD to start.
      #
      # @raise [Vanagon::Error] if a SSH connection cannot be established.
      # @return [void]
      def wait_for_ssh
        Vanagon::Utilities.retry_with_timeout(5, 5) do
          begin
            Vanagon::Utilities.remote_ssh_command("#{@target_user}@#{@target}", 'exit', @platform.ssh_port)
          rescue StandardError => e
            sleep(1) # Give SSHD some time to start.
            raise e
          end
        end
      rescue StandardError => e
        raise Vanagon::Error.wrap(e, "SSH was not up in the container after 5 seconds.")
      end
    end
  end
end

