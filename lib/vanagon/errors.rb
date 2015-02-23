class Vanagon

  # An error class that accepts a wrapped error message
  #
  class Error < StandardError
    attr_accessor :original

    # Generate a wrapped exception
    #
    # @param original [Exception] The exception to wrap
    # @param mesg [String]
    #
    # @return [Vanagon::Error]
    def self.wrap(original, mesg)
      new(mesg).tap do |e|
        e.set_backtrace(caller(4))
        e.original = original
      end
    end

    # @overload initialize(mesg)
    #   @param mesg [String] The exception mesg
    #
    def initialize(mesg)
      super(mesg)
    end
  end
end
