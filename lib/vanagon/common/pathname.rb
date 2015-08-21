class Vanagon
  class Common
    class Pathname
      attr_accessor :path, :mode, :owner, :group
      def initialize(path, mode = nil, owner = nil, group = nil)
        @path = path
        @mode = mode if mode
        @owner = owner if owner
        @group = group if group
      end

      # Simple test to see if any of the non-required attributes have been set in this object.
      #
      # @return [true, false] whether or not mode, owner or group has been set for the object
      def has_overrides?
        !!(@mode || @owner || @group)
      end

      # Equality. How does it even work?
      #
      # @return [true, false] true if all attributes have equal values. false otherwise.
      def ==(other)
        other.path == self.path && \
          other.mode == self.mode && \
          other.owner == self.owner && \
          other.group == self.group
      end

      # Override hash for this object, so that we can sanely remove duplicate pathnames
      #
      # @return [Fixnum] a hash for the Pathname, derived from the hashes of its attributes
      def hash
        [@path, @mode, @owner, @group].hash
      end

      # Override eql? for this object, so that we can sanely remove duplicate pathnames
      #
      # @param other [Vanagon::Common::Pathname] the other Pathname object to compare against
      # @return [true, false] true if all attributes have equal values. false otherwise.
      def eql?(other)
        self == other
      end
    end
  end
end
