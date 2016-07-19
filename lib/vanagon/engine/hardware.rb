require 'vanagon/engine/base'
require 'json'
require 'lock_manager'

LOCK_MANAGER_HOST = ENV['LOCK_MANAGER_HOST'] || 'redis'
LOCK_MANAGER_PORT = ENV['LOCK_MANAGER_PORT'] || 6379
VANAGON_LOCK_USER = ENV['USER']


class Vanagon
  class Engine
    # Class to use when building on a hardware device (e.g. AIX, Switch, etc)
    #
    class Hardware < Base
      # This method is used to obtain a vm to build upon
      # For the base class we just return the target that was passed in
      def select_target
        @target = node_lock(@build_hosts)
      end

      # Poll for a lock
      def polling_lock(host)
        Vanagon::Driver.logger.info "Polling for a lock on #{host}."
        @lockman.polling_lock(host, VANAGON_LOCK_USER, "Vanagon automated lock")
        Vanagon::Driver.logger.info "Lock acquired on #{host}."
        puts "Lock acquired on #{host} for #{VANAGON_LOCK_USER}."
        host
      end

      # Iterarte over the options and find a node open to lock.
      def node_lock(hosts)
        hosts.each do |h|
          Vanagon::Driver.logger.info "Attempting  to lock #{h}."
          if @lockman.lock(h, VANAGON_LOCK_USER, "Vanagon automated lock")
            Vanagon::Driver.logger.info "Lock acquired on #{h}."
            puts "Lock acquired on #{h} for #{VANAGON_LOCK_USER}."
            return h
          end
        end
        # If they are all locked, fall back to a polling lock on last item
        polling_lock(hosts.pop)
      end

      # Steps needed to tear down or clean up the system after the build is
      # complete. In this case, we'll attempt to unlock the hardware
      def teardown
        Vanagon::Driver.logger.info "Removing lock on #{@target}."
        puts "Removing lock on #{@target}."
        @lockman.unlock(@target, VANAGON_LOCK_USER)
      end

      def initialize(platform, target)
        super

        Vanagon::Driver.logger.debug "Hardware engine invoked."
        @build_hosts = platform.build_hosts
        # Redis is the only backend supported in lock_manager currently
        @lockman = LockManager.new(type: 'redis', server: LOCK_MANAGER_HOST)
        @required_attributes << "build_hosts"
      end

      # Get the engine name
      def name
        'hardware'
      end

      # Get the first build host name to build on
      def build_host_name
        if @build_host_name.nil?
          validate_platform
          # For now, get the first build host. In the future, lock management
          # will be pushed into the pooler (or something that wraps it), and
          # the hardware engine can go away.
          @build_host_name = @build_hosts.first
        end

        @build_host_name
      end
    end
  end
end
