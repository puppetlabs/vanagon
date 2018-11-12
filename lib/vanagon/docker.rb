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

    def build(workdir, options = {})
      docker_build_cmd = "#{docker_cmd} build"
      if tag = options[:tag]
        docker_build_cmd += " -t #{tag}"
      end

      Vanagon::Utilities.local_command("#{docker_build_cmd} #{workdir}")
    end
  end
end
