require 'time'

LIBDIR = File.expand_path(File.dirname(__FILE__))
VANAGON_ROOT = File.join(File.expand_path(File.dirname(__FILE__)), "..")
BUILD_TIME = Time.now.iso8601
VANAGON_VERSION = Gem.loaded_specs["vanagon"].version.to_s

$:.unshift(LIBDIR) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(LIBDIR)

require 'vanagon/optparse'
require 'vanagon/driver'
