LIBDIR = File.expand_path(File.dirname(__FILE__))
VANAGON_ROOT = File.join(File.expand_path(File.dirname(__FILE__)), "..")

$:.unshift(LIBDIR) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(LIBDIR)

require 'vanagon/driver'

class Vanagon

  def initialize(platform, project, configdir)
    @vanagon = Vanagon::Driver.new(platform, project, configdir)
  end

  def run(target, preserve = false, verbose = false)
    @vanagon.run(target, preserve)
  end
end
