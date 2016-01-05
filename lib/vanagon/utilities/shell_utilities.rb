class Vanagon
  module Utilities
    module ShellUtilities
      module_function

      # join a combination of strings and arrays of strings into a single command
      # joined with '&&'
      #
      # @param commands [Array<String, Array<String>>]
      # @return [String]
      def andand(*commands)
        cmdjoin(commands, " && ")
      end

      # join a combination of strings and arrays of strings into a single command
      # joined with '&&' and broken up with newlines after each '&&'
      #
      # @param commands [Array<String, Array<String>>]
      # @return [String]
      def andand_multiline(*commands)
        cmdjoin(commands, " && \\\n")
      end

      def cmdjoin(commands, sep)
        commands.map { |o| Array(o) }.flatten.join(sep)
      end
    end
  end
end
