require 'vanagon/utilities'

class Vanagon::Component
  include Vanagon::Utilities
  attr_accessor :name, :version, :source, :md5sum, :url, :configure, :build, :install, :dependencies, :environment, :extract_with, :dirname, :build_dependencies, :version, :settings, :platform, :service_files, :patches

  def self.load_component(name, configdir, settings, platform)
    compfile = File.join(configdir, "#{name}.rb")
    code = File.read(compfile)
    dsl = Vanagon::Component::DSL.new(name, settings, platform)
    dsl.instance_eval(code)
    dsl._component
  rescue => e
    puts "Error loading project '#{name}' using '#{compfile}':"
    puts e
    puts e.backtrace.join("\n")
    raise e
  end

  def initialize(name, settings, platform)
    @name = name
    @settings = settings
    @platform = platform
    @dependencies = []
    @build_dependencies = []
    @configure = []
    @install = []
    @build = []
    @patches = []
    @service_files = []
  end

  def get_source(workdir)
    puts "Fetching #{@url}..."
    @source = File.basename(fetch_source(@url, @md5sum, workdir))
    @extract_with = extract_source(@source)
    @dirname = get_dirname(@source)
  end
end
