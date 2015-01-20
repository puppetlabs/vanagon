require 'vanagon/platform/dsl'

class Vanagon
  class Platform
    attr_accessor :make, :servicedir, :defaultdir, :provisioning, :num_cores
    attr_accessor :build_dependencies, :name, :vcloud_name, :cflags, :ldflags, :settings
    attr_accessor :servicetype, :patch, :architecture, :codename, :os_name, :os_version

    # Platform names currently contain some information about the platform. Fields
    # within the name are delimited by the '-' character, and this regex can be used to
    # extract those fields.
    PLATFORM_REGEX = /^(.*)-(.*)-(.*)$/

    # Loads a given platform from the configdir
    #
    # @param name [String] the name of the platform
    # @param configdir [String] the path to the platform config file
    # @return [Vanagon::Platform] the platform as specified in the platform config
    # @raise if the instance_eval on Platform fails, the exception is reraised
    def self.load_platform(name, configdir)
      platfile = File.join(configdir, "#{name}.rb")
      code = File.read(platfile)
      dsl = Vanagon::Platform::DSL.new(name)
      dsl.instance_eval(code)
      dsl._platform
    rescue => e
      puts "Error loading platform '#{name}' using '#{platfile}':"
      puts e
      puts e.backtrace.join("\n")
      raise e
    end

    # Platform constructor. Takes just the name. Also sets the @name, @os_name,
    # \@os_version and @architecture instance attributes as a side effect
    #
    # @param name [String] name of the platform
    # @return [Vanagon::Platform] the platform with the given name
    def initialize(name)
      @name = name
      @os_name = os_name
      @os_version = os_version
      @architecture = architecture
    end

    # This allows instance variables to be accessed using the hash lookup syntax
    def [](key)
      if instance_variable_get("@#{key}")
        instance_variable_get("@#{key}")
      end
    end

    # Sets and gets the name of the operating system for the platform.
    # Also has the side effect of setting the @os_name instance attribute
    #
    # @return [String] the operating system name as specified in the platform
    def os_name
      @os_name ||= @name.match(PLATFORM_REGEX)[1]
    end

    # Sets and gets the version of the operating system for the platform.
    # Also has the side effect of setting the @os_version instance attribute
    #
    # @return [String] the operating system version as specified in the platform
    def os_version
      @os_version ||= @name.match(PLATFORM_REGEX)[2]
    end

    # Sets and gets the architecture of the platform.
    # Also has the side effect of setting the @architecture instance attribute
    #
    # @return [String] the architecture of the platform
    def architecture
      @architecture ||= @name.match(PLATFORM_REGEX)[3]
    end

    # Utility matcher to determine is the platform is a debian variety
    #
    # @return [true, false] true if it is a debian variety, false otherwise
    def is_deb?
      return !!@name.match(/^(debian|ubuntu|cumulus)-.*$/)
    end

    # Utility matcher to determine is the platform is a redhat variety or uses rpm under the hood
    #
    # @return [true, false] true if it is a redhat variety or uses rpm under the hood, false otherwise
    def is_rpm?
      return !!@name.match(/^(el|fedora|eos|nxos|sles)-.*$/)
    end

    # Utility matcher to determine is the platform is an enterprise linux variety
    #
    # @return [true, false] true if it is a enterprise linux variety, false otherwise
    def is_el?
      return !!@name.match(/^el-.*$/)
    end

    # Utility matcher to determine is the platform is a sles variety
    #
    # @return [true, false] true if it is a sles variety, false otherwise
    def is_sles?
      return !!@name.match(/^sles-.*$/)
    end

    # Utility matcher to determine is the platform is a fedora variety
    #
    # @return [true, false] true if it is a fedora variety, false otherwise
    def is_fedora?
      return !!@name.match(/^fedora-.*$/)
    end

    # Utility matcher to determine is the platform is an aix variety
    #
    # @return [true, false] true if it is an aix variety, false otherwise
    def is_aix?
      return !!@name.match(/^aix-.*$/)
    end

    # Utility matcher to determine is the platform is an eos variety
    #
    # @return [true, false] true if it is an eos variety, false otherwise
    def is_eos?
      return !!@name.match(/^eos-.*$/)
    end
  end
end
