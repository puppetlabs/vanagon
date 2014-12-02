require 'vanagon/platform/deb'
require 'vanagon/platform/rpm'

class Vanagon::Platform::DSL
  def initialize(name)
    @name = name
  end

  def platform(name, &block)
    @platform = case name
                when /^(el|sles)-/
                  Vanagon::Platform::RPM.new(@name)
                when /^(debian|ubuntu)-/
                  Vanagon::Platform::DEB.new(@name)
                else
                  fail "Platform not implemented for '#{@name}' yet. Please go do so..."
                end

    block.call(self)
    @platform
  end

  def _platform
    @platform
  end

  # Platform attributes and DSL methods defined below
  #
  #
  def make(make_cmd)
    @platform.make = make_cmd
  end

  def patch(patch_cmd)
    @platform.patch = patch_cmd
  end

  def provision_with(command)
    @platform.provisioning = command
  end

  def install_build_dependencies_with(command)
    @platform.build_dependencies = command
  end

  def servicedir(dir)
    @platform.servicedir = dir
  end

  def defaultdir(dir)
    @platform.defaultdir = dir
  end

  def servicetype(type)
    @platform.servicetype = type
  end

  def vcloud_name(name)
    @platform.vcloud_name = name
  end

  def codename(name)
    @platform.codename = name
  end
end
