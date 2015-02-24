LIBDIR = File.expand_path(File.dirname(__FILE__))
VANAGON_ROOT = File.join(File.expand_path(File.dirname(__FILE__)), "..")

$:.unshift(LIBDIR) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(LIBDIR)

require 'vanagon/optparse'
require 'vanagon/driver'
