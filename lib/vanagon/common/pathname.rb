require 'pathname'

class Vanagon
  class Common
    class Pathname
      # @!attribute path
      #   @return [String] Returns clean pathname of self with consecutive
      #     slashes and useless dots removed. The filesystem is not accessed.
      #
      # @!attribute mode
      #   @return [String, Integer] Returns an integer representing the
      #     permission bits of self. The meaning of the bits is platform
      #     dependent; on Unix systems, see stat(2).
      #
      # @!attribute owner
      #   @return [String, Integer] Returns the numeric user id or string
      #     representing the user name of the owner of self.
      #
      # @!attribute group
      #   @return [String, Integer] Returns the numeric group id or string
      #     representing the group name of the owner of self.
      attr_accessor :path, :mode, :owner, :group

      # Each Pathname requires a filesystem path, and has many optional
      # properties that may be set at initialization time.
      # @param [String, Integer] mode the UNIX Octal permission string to use when this file is archived
      # @param [String, Integer] owner the username or UID to use when this file is archived
      # @param [String, Integer] group the groupname or GID to use when this file is archived
      # @param [Boolean] config mark this file as a configuration file, stored as private state
      #   and exposed through the {#configfile?} method.
      # @return [Vanagon::Common::Pathname] Returns a new Pathname instance.
      def initialize(path, mode: nil, owner: nil, group: nil, config: false)
        @path = ::Pathname.new(path).cleanpath.to_s
        @mode ||= mode
        @owner ||= owner
        @group ||= group
        @config ||= config
      end

      # An alias to {Vanagon::Common::Pathname}'s constructor method,
      #   which returns a new Vanagon::Common::Pathname, explicitly marked as a file
      # @see Vanagon::Common::Pathname#initialize
      #
      # @example Create a new Vanagon::Common::Pathname, marked as a file.
      #   Vanagon::Common::Pathname.file('/etc/puppet/puppet/puppet.conf')
      def self.file(path, **args)
        new(path, **args.merge!({ config: false }))
      end

      # An alias to {Vanagon::Common::Pathname}'s constructor method,
      #   which returns a new Vanagon::Common::Pathname, explicitly marked as a configuration file
      # @see Vanagon::Common::Pathname#initialize
      #
      # @example Create a new configuration file, marked as a configuration file.
      #   Vanagon::Common::Pathname.configfile('/etc/puppet/puppet/puppet.conf')
      def self.configfile(path, **args)
        new(path, **args.merge!({ config: true }))
      end

      # @return [Boolean] true if a self is marked as a configuration file.
      def configfile?
        !!@config
      end

      # Simple test to see if any of the non-required attributes have been set in this object.
      #
      # @return [Boolean] whether or not mode, owner or group has been set for the object
      def has_overrides?
        !!(@mode || @owner || @group)
      end

      # Equality -- Two instances of Vanagon::Common::Pathname are equal if they
      #   contain the same number attributes and if each attribute is equal to
      #   (according to {Object#==}) the corresponding attribute in other_pathname.
      #
      # @return [Boolean] true if all attributes have equal values, or otherwise false.
      def ==(other)
        other.hash == hash
      end
      alias :eql? :==

      # @return [Fixnum] Compute a hash-code for self, derived from its attributes;
      #   two Pathnames with the same content will have the same hash code (and will compare using {#eql?}).
      def hash
        instance_variables.map { |v| instance_variable_get(v) }.hash
      end
    end
  end
end
