require 'vanagon/platform/deb'
require 'vanagon/platform/rpm'

class Vanagon
  class Platform
    class DSL
      def initialize(name)
        @name = name
      end

      def platform(name, &block)
        @platform = case name
                    when /^(el|sles)-/
                      Vanagon::Platform::RPM.new(@name)
                    when /^(debian|ubuntu)-/
                      Vanagon::Platform::DEB.new(@name)
                    else
                      fail "Platform not implemented for '#{@name}' yet. Please go do so..."
                    end

        block.call(self)
        @platform
      end

      def _platform
        @platform
      end

      # All purpose getter. This object, which is passed to the platform block,
      # won't have easy access to the attributes of the @platform, so we make a
      # getter for each attribute.
      #
      # We only magically handle get_ methods, any other methods just get the
      # standard method_missing treatment.
      #
      def method_missing(method, *args)
        attribute_match = method.to_s.match(/get_(.*)/)
        if attribute_match
          attribute = attribute_match.captures.first
        else
          super
        end

        @platform.send(attribute)
      end

      # Platform attributes and DSL methods defined below
      #
      #
      def make(make_cmd)
        @platform.make = make_cmd
      end

      def patch(patch_cmd)
        @platform.patch = patch_cmd
      end

      def provision_with(command)
        @platform.provisioning = command
      end

      def install_build_dependencies_with(command)
        @platform.build_dependencies = command
      end

      def servicedir(dir)
        @platform.servicedir = dir
      end

      def defaultdir(dir)
        @platform.defaultdir = dir
      end

      def servicetype(type)
        @platform.servicetype = type
      end

      def vcloud_name(name)
        @platform.vcloud_name = name
      end

      def codename(name)
        @platform.codename = name
      end
    end
  end
end
