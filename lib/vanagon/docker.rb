require 'vanagon/docker/container'
require 'vanagon/utilities'
require 'vanagon/utilities/shell_utilities'

class Vanagon
  # Docker is a module that is meant to encapsulate common Docker
  # commands like `docker build` and `docker run` in a more
  # idiomatic way.
  module Docker
    extend self

    def docker(args, options = {})
      docker_cmd = Vanagon::Utilities.find_program_on_path('docker')
      Vanagon::Utilities.local_command("#{docker_cmd} #{args}", options)
    end

    def build(workdir, options = {})
      build_args = "build"
      if tag = options[:tag]
        build_args += " -t #{tag}"
      end
      build_args += " #{workdir}"

      docker(build_args)
    end

    def in_container(name, image_tag, options, &block)
      container = Vanagon::Docker::Container.new(name, image_tag, options)
      begin
        container.create
        yield container
      ensure
        container.destroy
      end
    end
  end
end
