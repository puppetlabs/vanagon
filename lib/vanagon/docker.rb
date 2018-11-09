require 'vanagon/utilities/shell_utilities'

class Vanagon
  # Docker is a module that is meant to encapsulate common Docker
  # commands like `docker build` and `docker run` in a more
  # idiomatic way.
  module Docker
    extend self

    def docker_cmd
      Vanagon::Utilities.find_program_on_path('docker')
    end

    def build(workdir)
      Vanagon::Utilities.local_command("#{docker_cmd} build #{workdir}")
    end
  end
end
