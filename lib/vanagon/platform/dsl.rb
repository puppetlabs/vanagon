require 'vanagon/platform/deb'
require 'vanagon/platform/rpm'

class Vanagon::Platform::DSL
  def initialize(name)
    @name = name
  end

  def platform(name, &block)
    @platform = case name
                when /^el-/
                  Vanagon::Platform::RPM.new(@name)
                when /^(debian|ubuntu)-/
                  Vanagon::Platform::DEB.new(@name)
                else
                  fail "Platform not implemented for '#{@name}' yet. Please go do so..."
                end

    block.call(@platform)
    @platform
  end

  def _platform
    @platform
  end
end
