class Vanagon
  module Docker
    # Docker::Container encapsulates a docker container
    class Container
      attr_reader :name

      def initialize(name, image, options = {})
        @name = name
        @image = image
        @volumes = options[:volumes]
      end

      def create
        volume_flags = @volumes.map do |source, dest|
          "-v #{source}:#{dest}"
        end.join(" ")

        puts "Creating the #{@name} container from the #{@image} image ..."
        Vanagon::Docker.docker("run -t -d #{volume_flags} --name #{@name} #{@image}")
      end

      def exec(cmd, options = {})
        puts "#{cmd} (#{@name})"
        Vanagon::Docker.docker("exec #{@name} #{cmd}")
      end

      def destroy
        puts "Destroying the #{@name} container ..."

        Vanagon::Docker.docker("stop #{@name}")
        Vanagon::Docker.docker("rm #{@name}")
      end
    end
  end
end
