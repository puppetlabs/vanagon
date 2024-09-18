class Vanagon
  class Common
    class User
      attr_accessor :name, :group, :shell, :is_system, :homedir

      def initialize(name, group = nil, shell = nil, is_system = false, homedir = nil)
        @name = name
        @group = group ? group : @name
        @shell = shell if shell
        @is_system = is_system if is_system
        @homedir = homedir if homedir
      end

      # Equality. How does it even work?
      #
      # @return [true, false] true if all attributes have equal values. false otherwise.
      def ==(other)
        other.name == self.name &&
          other.group == self.group &&
          other.shell == self.shell &&
          other.is_system == self.is_system &&
          other.homedir == self.homedir
      end
    end
  end
end
