require 'vanagon/engine/base'
require 'json'
require 'lock_manager'

LOCK_MANAGER_HOST = ENV['LOCK_MANAGER_HOST'] || 'redis'
LOCK_MANAGER_PORT = ENV['LOCK_MANAGER_PORT'] || 6379
VANAGON_LOCK_USER = "#{ENV['USER']}"


class Vanagon
  class Engine
    # Class to use when building on a hardware device (e.g. AIX, Switch, etc)
    #
    class Hardware < Base

      # This method is used to obtain a vm to build upon
      # For the base class we just return the target that was passed in
      def select_target
        Vanagon::Driver.logger.info "Polling for a lock on #{@build_host}."
        @lockman.polling_lock(@build_host, VANAGON_LOCK_USER, "Vanagon automated lock")
        Vanagon::Driver.logger.info "Lock acquired on #{@build_host}."
        warn "Lock acquired on #{@build_host} for #{VANAGON_LOCK_USER}."
        @target = @build_host
        @build_host
      end

      # Steps needed to tear down or clean up the system after the build is
      # complete. In this case, we'll attempt to unlock the hardware
      def teardown
        Vanagon::Driver.logger.info "Removing lock on #{@build_host}."
        warn "Removing lock on #{@build_host}."
        @lockman.unlock(@build_host, VANAGON_LOCK_USER)
      end

      def initialize(platform, target)
        Vanagon::Driver.logger.debug "Hardware engine invoked."
        @platform = platform
        @build_host = platform.build_host
        # Redis is the only backend supported in lock_manager currently
        @lockman = LockManager.new(type: 'redis', server: LOCK_MANAGER_HOST)
        super
        @required_attributes << "build_host"
      end
    end
  end
end
