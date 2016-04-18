class Vanagon
  class Engine
    # Find all potential Engines bundled with Vanagon and save them for later
    @default_engines = Dir.glob(File.join(File.dirname(__FILE__), "engine", "*rb"))
    # Initialize a Hash to store information on registered Engines
    # once they're successfully initialized
    @registered_engines = {}

    # Each Engine must define these parameters to pass validation.
    # The Array is frozen after initialization because this is
    # probably the closest we're going to get to anything resembling
    # a Contract in Ruby.
    @required_attributes = %w(engine_name desc remote teardown).freeze

    # @param engine [Class] an instance of an Engine subclass to register
    # @return [Hash] the new value of @registered_engines, containing the
    #   Registry information for `engine`
    def self.register(engine)
      validate(engine)
      @registered_engines[engine.engine_name.to_sym] = engine
    end

    # @return [Hash] all Engines currently registered
    def self.registered_engines
      @registered_engines
    end

    # Ensures that a new Engine defines the attributes required for registration.
    # @param engine [Class] an instance of an Engine subclass to validate
    # @return [True] if an engine passes validation
    # @raise [Vanagon::Error] a list of errors that are raised if an engine
    #   doesn't define a required attribute
    def self.validate(engine)
      attrs = check_required_attributes(engine)
      return true if attrs.empty?
      raise Vanagon::Error,
            "The following required attributes were not set in '#{engine.engine_name}': #{attrs.join(', ')}."
    end

    def self.register_engines!(engines = @default_engines)
      [*engines].flatten.each do |engine|
        require engine
      end
    end

    # def initialize(engine_type, platform, target)
    #   self.class.registered_engines[engine_type]
    # end

    class << self
      # Validate that all required attributes are defined for a given
      # Engine instance. Will log a warning for each missing attribute.
      # @param engine [Class] an instance of an Engine:: subclass to validate
      # @return [Array] a list of all of an Engine's missing attributes
      # @private
      def check_required_attributes(engine)
        @required_attributes.each_with_object([]) do |attr, arr|
          if engine.send(attr).nil?
            warn "#{engine.name} is missing required attributes #{attr}"
            arr << attr
          end
        end
      end
      private :check_required_attributes
    end
  end
end
