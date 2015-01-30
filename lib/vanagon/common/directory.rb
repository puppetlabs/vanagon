class Vanagon
  class Common
    class Directory
      attr_accessor :path, :mode, :owner, :group
      def initialize(path, mode = nil, owner = nil, group = nil)
        @path = path
        @mode = mode if mode
        @owner = owner if owner
        @group = group if group
      end

      def has_overrides?
        @mode || @owner || @group
      end
    end
  end
end
