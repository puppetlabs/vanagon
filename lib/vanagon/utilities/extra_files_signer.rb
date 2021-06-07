class Vanagon
  module Utilities
    module ExtraFilesSigner
      class << self
        def commands(project, mktemp, source_dir) # rubocop:disable Metrics/AbcSize
          tempdir = nil
          commands = []
          # Skip signing extra files if logging into the signing_host fails
          # This enables things like CI being able to sign the additional files,
          # but locally triggered builds by developers who don't have access to
          # the signing host just print a message and skip the signing.
          Vanagon::Utilities.retry_with_timeout(3, 5) do
            tempdir = Vanagon::Utilities::remote_ssh_command("#{project.signing_username}@#{project.signing_hostname}", "#{mktemp} 2>/dev/null", return_command_output: true)
          end

          project.extra_files_to_sign.each do |file|
            file_location = File.join(tempdir, File.basename(file))
            local_source_path = File.join('$(tempdir)', source_dir, file)
            remote_host = "#{project.signing_username}@#{project.signing_hostname}"
            remote_destination_path = "#{remote_host}:#{tempdir}"
            remote_file_location = "#{remote_host}:#{file_location}"

            commands += [
              "rsync -e '#{Vanagon::Utilities.ssh_command}' --verbose --recursive --hard-links --links  --no-perms --no-owner --no-group #{local_source_path} #{remote_destination_path}",
              "#{Vanagon::Utilities.ssh_command} #{remote_host} #{project.signing_command} #{file_location}",
              "rsync -e '#{Vanagon::Utilities.ssh_command}' --verbose --recursive --hard-links --links  --no-perms --no-owner --no-group #{remote_file_location} #{local_source_path}"
            ]
          end

          commands
        rescue RuntimeError
          require 'vanagon/logger'
          VanagonLogger.error "Unable to connect to #{project.signing_username}@#{project.signing_hostname}, skipping signing extra files: #{project.extra_files_to_sign.join(',')}"
          []
        end
      end
    end
  end
end
