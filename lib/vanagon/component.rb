require 'vanagon/utilities'

class Vanagon::Component
  include Vanagon::Utilities
  attr_accessor :name, :version, :source, :md5sum, :url, :configure, :build, :install, :dependencies, :environment, :extract_with, :dirname, :build_dependencies, :version, :settings, :platform, :service_files, :patches

  def initialize
    @dependencies = []
    @build_dependencies = []
    @configure = []
    @install = []
    @build = []
    @patches = []
    @service_files = []
  end

  def configure_with(&block)
    @configure = block.call
  end

  def build_with(&block)
    @build = block.call
  end

  def install_with(&block)
    @install = block.call
  end

  def environment_with(&block)
    @environment = block.call
  end

  def depends_on(dependency)
    @dependencies << dependency
  end

  def apply_patch(patch, flag = nil)
    @patches << patch
  end

  def add_service_file(file)
    @service_files << file
  end

  def get_source(workdir)
    puts "Fetching #{@url}..."
    @source = File.basename(fetch_source(@url, @md5sum, workdir))
    @extract_with = extract_source(@source)
    @dirname = get_dirname(@source)
  end

  def build_depends_on(dependency)
    @build_dependencies << dependency
  end

  def component(name, &block)
    @name = name
    block.call(self, @settings, @platform)
  end
end
