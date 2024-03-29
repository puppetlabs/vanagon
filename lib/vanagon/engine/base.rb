require 'vanagon/utilities'
require 'vanagon/errors'

class Vanagon
  class Engine
    class Base
      attr_accessor :target, :remote_workdir

      def initialize(platform, target = nil, **opts)
        @platform = platform
        @required_attributes = ["ssh_port"]
        parse_target_defaults(target) if target
        @target_port ||= @platform.ssh_port
        @target_user ||= @platform.target_user
        @remote_workdir_path = opts[:remote_workdir]
      end

      # Get the engine name
      def name
        'base'
      end

      def parse_target_defaults(target)
        # If there's no scheme, we need to add // to make it parse properly
        target_uri = target.include?('//') ? URI.parse(target) : URI.parse("//#{target}")
        @target = target_uri.hostname
        @target_port = target_uri.port
        @target_user = target_uri.user
      rescue URI::Error
        # Just assume it's not meant to be a URI
        @target = target
      end

      # Get the engine specific name of the host to build on
      def build_host_name
        raise Vanagon::Error, '#build_host_name has not been implemented for your engine.'
      end

      # This method is used to obtain a vm to build upon
      # For the base class we just return the target that was passed in
      def select_target
        @target or raise Vanagon::Error, '#select_target has not been implemented for your engine.'
      end

      # Dispatches the command for execution
      def dispatch(command, return_output = false)
        Vanagon::Utilities.remote_ssh_command("#{@target_user}@#{@target}", command, @target_port, return_command_output: return_output)
      end

      # Steps needed to tear down or clean up the system after the build is
      # complete
      def teardown; end

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
        unless @remote_workdir
          if @remote_workdir_path
            dispatch("mkdir -p #{@remote_workdir_path}", true)
            @remote_workdir = @remote_workdir_path
          else
            @remote_workdir = dispatch("#{@platform.mktemp} 2>/dev/null", true)
          end
        end
        @remote_workdir
      end

      def ship_workdir(workdir)
        Vanagon::Utilities.rsync_to("#{workdir}/*", "#{@target_user}@#{@target}", @remote_workdir, @target_port)
      end

      def retrieve_built_artifact(artifacts_to_fetch, no_packaging)
        output_path = 'output/'
        FileUtils.mkdir_p(output_path)
        unless no_packaging
          artifacts_to_fetch << "#{@remote_workdir}/output/*"
        end
        artifacts_to_fetch.each do |path|
          Vanagon::Utilities.rsync_from(path, "#{@target_user}@#{@target}", output_path, @target_port)
        end
      end

      # Ensures that the platform defines the attributes that the engine needs to function.
      #
      # @raise [Vanagon::Error] an error is raised if a needed attribute is not defined
      def validate_platform
        missing_attrs = []
        @required_attributes.each do |attr|
          if !@platform.instance_variables.include?("@#{attr}".to_sym) || @platform.instance_variable_get("@#{attr}".to_sym).nil?
            missing_attrs << attr
          end
        end

        if missing_attrs.empty?
          return true
        else
          raise Vanagon::Error, "The following required attributes were not set in '#{@platform.name}': #{missing_attrs.join(', ')}."
        end
      end
    end
  end
end
