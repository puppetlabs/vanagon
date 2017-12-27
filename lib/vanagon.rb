require 'time'

LIBDIR = __dir__
VANAGON_ROOT = File.join(__dir__, "..")
BUILD_TIME = Time.now.iso8601
VANAGON_VERSION = Gem.loaded_specs["vanagon"].version.to_s

$:.unshift(LIBDIR) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(LIBDIR)

require 'vanagon/optparse'
require 'vanagon/driver'

# The main entry point is {Vanagon::Driver}.
class Vanagon
end
