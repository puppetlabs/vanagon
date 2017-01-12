require 'vanagon/engine/base'
require 'json'

class Vanagon
  class Engine
    # This engine allows build resources to be managed by the "Always be
    # Scheduling" (ABS) scheduler (https://github.com/puppetlabs/always-be-scheduling)
    #
    # ABS expects to ask `build_host_info` for the needed resources for a build,
    # and to have that return a platform name.  ABS will then acquire the
    # desired build host resources and will later run a vanagon build, passing
    # those resource hostnames in specifically.
    #
    # `build_host_info` will normally use the `hardware` engine when a hardware
    # platform is queried. The `always_be_scheduling` engine's behavior will
    # be invoked instead when:
    #
    # `build_host_info ... --engine always_be_scheduling` is specified on the
    # command-line.
    #
    # Configuration:
    #
    # Project platform configurations can specify the platform name to be returned
    # via the `abs_resource_name` attribute. If this is not set but `vmpooler_template`
    # is set, then the `vmpooler_template` value will be used. Otherwise, the
    # platform name will be returned unchanged.
    #
    # Example 1:
    #
    # platform 'ubuntu-10.04-amd64' do |plat|
    #   plat.vmpooler_template 'ubuntu-1004-amd64'
    # end
    #
    # $ build_host_info puppet-agent ubuntu-10.04-amd64
    # {"name":"ubuntu-10.04-amd64","engine":"pooler"}
    #
    # $ build_host_info puppet-agent ubuntu-10.04-amd64 --engine always_be_scheduling
    # {"name":"ubuntu-10.04-amd64","engine":"always_be_scheduling"}
    #
    #
    # Example 2:
    #
    # platform 'aix-5.3-ppc' do |plat|
    #   plat.build_host ['aix53-builder-1.example.com']
    #   plat.abs_resource_name 'aix-53-ppc'
    # end
    #
    # $ build_host_info puppet-agent aix-5.3-ppc
    # {"name":"aix53-builder-1.example.com","engine":"hardware"}
    #
    # $ build_host_info puppet-agent aix-5.3-ppc --engine always_be_scheduling
    # {"name":"aix-53-ppc","engine":"always_be_scheduling"}
    #
    #
    # Example 3:
    #
    # platform 'aix-5.3-ppc' do |plat|
    #   plat.build_host ['aix53-builder-1.example.com']
    #   plat.vmpooler_template
    #   plat.abs_resource_name 'aix-53-ppc'
    # end
    #
    # $ build_host_info puppet-agent aix-5.3-ppc
    # {"name":"aix53-builder-1.example.com","engine":"hardware"}
    #
    # $ build_host_info puppet-agent aix-5.3-ppc --engine always_be_scheduling
    # {"name":"aix-53-ppc","engine":"always_be_scheduling"}
    class AlwaysBeScheduling < Base
      def initialize(platform, target, opts = {})
        super

        Vanagon::Driver.logger.debug "AlwaysBeScheduling engine invoked."
      end

      # Get the engine name
      def name
        'always_be_scheduling'
      end

      # return the platform name as the "host" name
      def build_host_name
        if @platform.abs_resource_name
          @platform.abs_resource_name
        elsif @platform.vmpooler_template
          @platform.vmpooler_template
        else
          @platform.name
        end
      end
    end
  end
end
