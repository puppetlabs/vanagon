require 'vanagon/utilities'
require 'vanagon/errors'
require 'vanagon/engine'

class Vanagon
  class Engine
    # Base is the Engine subclass that all other Engines subclasses should inherit from.
    # It defines the general interface of an Engine, and gives them the ability to
    # register themselves with the Vanagon::Engine class. Without inheriting from Base,
    # a new Engine has to completely reimplement the loosely binding Constract of
    # required attributes & methods.
    class Base
      attr_accessor :target, :remote_workdir, :name

      class << self
        attr_accessor :engine_name, :desc, :remote, :teardown

        # # Provide a formatted hash that Vanagon::Engine will use
        # # to add an Engine subclass to the global Engine registry.
        # # @return [Hash] the Registry information for `engine`, derived
        # #   from the values of @engine_name, @desc, @remote, and @teardown
        # def registry
        #   {
        #     engine_name.to_sym => {
        #       desc: desc, remote: remote, teardown: teardown
        #     }
        #   }
        # end
      end

      # This Engine has a name, which will be used as an index key
      # when this Engine is registered.
      @engine_name = "base"
      # A description of this Engine.
      @desc = "Pure SSH backend; no teardown defined"
      # Whether or not this Engine is remote/relies on a remote host.
      @remote = true
      # Whether or not this Engine supports teardown at the end
      # of a build.
      @teardown = false

      # @return [Boolean] whether or not this engine relies
      #   on a remote host
      def self.remote?
        !!remote
      end
      # @return [Boolean] whether or not this engine supports
      #   teardown at the end of a build
      def self.teardown?
        !!teardown
      end

      def initialize(platform, target = nil)
        @platform = platform
        @required_attributes = ["ssh_port"]
        @target = target if target
        @target_user = @platform.target_user
        @name = 'base'
      end

      # This method is used to obtain a vm to build upon
      # For the base class we just return the target that was passed in
      def select_target
        @target or raise Vanagon::Error, '#select_target has not been implemented for your engine.'
      end

      # Dispatches the command for execution
      def dispatch(command, return_output = false)
        Vanagon::Utilities.remote_ssh_command("#{@target_user}@#{@target}", command, @platform.ssh_port, return_command_output: return_output)
      end

      # Steps needed to tear down or clean up the system after the build is
      # complete
      def teardown
      end

      # Applies the steps needed to extend the system to build packages against
      # the target system
      def setup
        unless @platform.provisioning.empty?
          script = @platform.provisioning.join(' && ')
          dispatch(script)
        end
      end

      # This method will take care of validation and target selection all at
      # once as an easy shorthand to call from the driver
      def startup(workdir)
        validate_platform
        select_target
        setup
        get_remote_workdir
      end

      def get_remote_workdir
        @remote_workdir ||= dispatch("mktemp -d -p /var/tmp 2>/dev/null || mktemp -d -t 'tmp'", true)
      end

      def ship_workdir(workdir)
        Vanagon::Utilities.rsync_to("#{workdir}/*", "#{@target_user}@#{@target}", @remote_workdir, @platform.ssh_port)
      end

      def retrieve_built_artifact
        FileUtils.mkdir_p("output")
        Vanagon::Utilities.rsync_from("#{@remote_workdir}/output/*", "#{@target_user}@#{@target}", "output/", @platform.ssh_port)
      end

      # Ensures that the platform defines the attributes that the engine needs to function.
      #
      # @raise [Vanagon::Error] an error is raised if a needed attribute is not defined
      def validate_platform
        missing_attrs = []
        @required_attributes.each do |attr|
          if (!@platform.instance_variables.include?("@#{attr}".to_sym)) or @platform.instance_variable_get("@#{attr}".to_sym).nil?
            missing_attrs << attr
          end
        end

        if missing_attrs.empty?
          return true
        else
          raise Vanagon::Error, "The following required attributes were not set in '#{@platform.name}': #{missing_attrs.join(', ')}."
        end

        # This should be the last thing that an Engine declares because
        # if it's too early in the call-stack, then the attr_accessors
        # that registration relies on aren't defined yet.
        Vanagon::Engine.register self
      end
    end
  end
end
