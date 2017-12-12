require 'forwardable'
require 'vanagon/extensions/string'

class Vanagon
  # Environment is a validating wrapper around a delegated Hash,
  # analogous to Ruby's built in accessor Env. It's intended to be
  # used for defining multiple Environments, which can be used and
  # manipulated the same way a bare Hash would be. We're delegating
  # instead of subclassing because subclassing from Ruby Core is
  # inviting calamity -- that stuff is written in C and may not
  # correspond to assumptions you could safely make about Ruby.
  class Environment
    extend Forwardable
    # @!method []
    #   @see Hash#[]
    # @!method keys
    #   @see Hash#keys
    # @!method values
    #   @see Hash#values
    # @!method empty?
    #   @see Hash#empty?
    def_delegators :@data, :[], :keys, :values, :empty?

    # @!method each
    #   @see Hash#each
    # @!method each_pair
    #   @see Hash#each_pair
    def_delegators :@data, :each, :each_pair, :each_key, :each_value
    def_delegators :@data, :each_with_index, :each_with_object
    def_delegators :@data, :map, :flat_map

    # @!method delete
    #   @see Hash#delete
    # @!method delete_if
    #   @see Hash#delete_if
    def_delegators :@data, :delete, :delete_if

    # @!method to_h
    #   @see Hash#to_h
    # @!method to_hash
    #   @see Hash#to_h
    def_delegators :@data, :to_h, :to_hash

    # Create a new Environment
    # @return [Vanagon::Environment] a new Environment, with no defined env. vars.
    def initialize
      @data = {}
    end

    # Associates the value given by value with the key given by key. Keys will
    # be cast to Strings, and should conform to the Open Group's guidelines for
    # portable shell variable names:
    #
    #     Environment variable names used by the utilities in the Shell and
    #     Utilities volume of IEEE Std 1003.1-2001 consist solely of uppercase
    #     letters, digits, and the '_' (underscore) from the characters defined
    #     in Portable Character Set and do not begin with a digit.
    #
    # Values will be cast to Strings, and will be stored precisely as given,
    # so any escaped characters, single or double quotes, or whitespace will be
    # preserved exactly as passed during assignment.
    #
    # @param key [String]
    # @param value [String, Integer]
    # @raise [ArgumentError] if key or value cannot be cast to a String
    def []=(key, value)
      @data.update({ validate_key(key) => validate_value(value) })
    end

    # Returns a new Environment containing the contents of other_env and the
    # contents of env.
    # @param other_env [Environment]
    # @example Merge two Environments
    #   >> local = Vanagon::Environment.new
    #   => #<Vanagon::Environment:0x007fc54d913f38 @data={}>
    #   >> global = Vanagon::Environment.new
    #   => #<Vanagon::Environment:0x007fc54b06da70 @data={}>
    #   >> local['PATH'] = '/usr/local/bin:/usr/bin:/bin'
    #   >> global['CC'] = 'ccache gcc'
    #   >> local.merge global
    #   => #<Vanagon::Environment:0x007fc54b0a72e8 @data={"PATH"=>"/usr/local/bin:/usr/bin:/bin", "CC"=>"ccache gcc"}>
    def merge(other_env)
      env_copy = self.dup
      other_env.each_pair do |k, v|
        env_copy[k] = v
      end
      env_copy
    end
    alias update merge

    # Adds the contents of other_env to env.
    # @param other_env [Environment]
    # @example Merge two Environments
    #   >> local = Vanagon::Environment.new
    #   => #<Vanagon::Environment:0x007f8c68933b08 @data={}>
    #   >> global = Vanagon::Environment.new
    #   => #<Vanagon::Environment:0x007f8c644e5640 @data={}>
    #   >> local['PATH'] = '/usr/local/bin:/usr/bin:/bin'
    #   >> global['CC'] = 'ccache gcc'
    #   >> local.merge! global
    #   => #<Vanagon::Environment:0x007f8c68933b08 @data={"PATH"=>"/usr/local/bin:/usr/bin:/bin", "CC"=>"ccache gcc"}>
    def merge!(other_env)
      @data = merge(other_env).instance_variable_get(:@data)
    end

    # Converts env to an array of "#{key}=#{value}" strings, suitable for
    # joining into a command.
    # @example Convert to an Array
    #   >> local = Vanagon::Environment.new
    #   => #<Vanagon::Environment:0x007f8c68991258 @data={}>
    #   >> local['PATH'] = '/usr/local/bin:/usr/bin:/bin'
    #   => "/usr/local/bin:/usr/bin:/bin"
    #   >> local['CC'] = 'clang'
    #   => "clang"
    #   >> local.to_a
    #   => ["PATH=\"/usr/local/bin:/usr/bin:/bin\"", "CC=\"clang\""]
    def to_a(delim = "=")
      @data.map { |k, v| %(#{k}#{delim}#{v}) }
    end
    alias to_array to_a

    # Converts env to a string by concatenating together all key-value pairs
    # with a single space.
    # @example Convert to an Array
    #   >> local = Vanagon::Environment.new
    #   => #<Vanagon::Environment:0x007f8c68014358 @data={}>
    #   >> local['PATH'] = '/usr/local/bin:/usr/bin:/bin'
    #   >> local['CC'] = 'clang'
    #   >> puts local
    #   PATH=/usr/local/bin:/usr/bin:/bin
    #   >>
    def to_s
      to_a.join("\s")
    end
    alias to_string to_s

    def sanitize_subshells(str)
      pattern = %r{\$\$\((.*?)\)}
      escaped_variables = str.scan(pattern).flatten
      return str if escaped_variables.empty?

      warning = [%(Value "#{str}" looks like it's escaping one or more values for subshell interpolation.)]
      escaped_variables.each { |v| warning.push %(\t"$$(#{v})" will be coerced to "$(shell #{v})") }
      warning.push <<-eos.undent
        All environment variables will now be resolved by Make before they're executed
        by the shell. These variables will be mangled for you for now, but you should
        update your project's parameters.
      eos

      warn warning.join("\n")
      str.gsub(pattern, '$(shell \1)')
    end
    private :sanitize_subshells

    def sanitize_variables(str)
      pattern = %r{\$\$([\w]+)}
      escaped_variables = str.scan(pattern).flatten
      return str if escaped_variables.empty?

      warning = [%(Value "#{str}" looks like it's escaping one or more shell variable names for shell interpolation.)]
      escaped_variables.each { |v| warning.push %(\t"$$#{v}" will be coerced to "$(#{v})") }
      warning.push <<-eos.undent
        All environment variables will now be resolved by Make before they're executed
        by the shell. These variables will be mangled for you for now, but you should
        update your project's parameters.
      eos

      warn warning.join("\n")
      str.gsub(pattern, '$(\1)')
    end
    private :sanitize_variables

    # Cast key to a String, and validate that it does not contain invalid
    #   characters, and that it does not begin with a digit
    # @param key [Object]
    # @raise [ArgumentError] if key is not a String, if key contains invalid
    #   characters, or if key begins with a digit
    def validate_key(str)
      str = str.to_s

      if str[0] =~ /\d/
        raise ArgumentError,
              'environment variable Name cannot begin with a digit'
      end

      invalid_chars = str.scan(/[^\w]/).uniq
      unless invalid_chars.empty?
        raise ArgumentError,
              'environment variable Name contains invalid characters: ' +
              invalid_chars.map { |char| %("#{char}") }.join(', ')
      end
      str
    end
    private :validate_key

    # Cast str to a String, and validate that the value
    # of str cannot be split into more than a single String by #shellsplit.
    # @param value [Object]
    def validate_value(str)
      # sanitize the value, which should look for any Shell escaped
      # variable names inside of the value.
      sanitize_variables(sanitize_subshells(str.to_s))
    end
    private :validate_value
  end
end
