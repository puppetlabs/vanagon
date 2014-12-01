require 'vanagon/platform/dsl'

class Vanagon::Platform
  attr_accessor :make, :servicedir, :defaultdir, :provisioning, :build_dependencies, :name, :vcloud_name, :cflags, :ldflags, :settings, :servicetype, :patch, :architecture

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

  def initialize(name)
    @name = name
  end

  # This allows instance variables to be accessed using the hash lookup syntax
  def [](key)
    if instance_variable_get("@#{key}")
      instance_variable_get("@#{key}")
    end
  end

  def architecture
    @architecture ||= @name.match(/^.*-.*-(.*)$/)[1]
  end


  # Debian/Ubuntu/Cumulus specific utility to convert a platform to its codename
  def to_codename
    fail "#to_codename not implemented for non-debian platforms" unless is_deb?
    case @name
    when /^ubuntu-(.*)-.*$/
      case $1
      when "14.10"
        "utopic"
      when "14.04"
        "trusty"
      when "12.04"
        "precise"
      when "10.04"
        "lucid"
      else
        "ubuntu"
      end
    when /^debian-(.*)-.*$/
      case $1
      when "6"
        "squeeze"
      when "7"
        "wheezy"
      when "8"
        "jessie"
      else
        "debian"
      end
    end
  end

  #
  # Utilities for platform matching
  #

  def is_deb?
    return !!@name.match(/^(debian|ubuntu|cumulus)-.*$/)
  end

  def is_rpm?
    return !!@name.match(/^(el|fedora|eos|nxos|sles)-.*$/)
  end

  def is_el?
    return !!@name.match(/^el-.*$/)
  end

  def is_sles?
    return !!@name.match(/^sles-.*$/)
  end

  def is_fedora?
    return !!@name.match(/^fedora-.*$/)
  end

  def is_aix?
    return !!@name.match(/^aix-.*$/)
  end
end
