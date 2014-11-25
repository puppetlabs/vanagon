require 'vanagon/component'
require 'vanagon/platform'
require 'vanagon/utilities'
require 'ostruct'

class Vanagon::Project
  include Vanagon::Utilities
  attr_accessor :components, :settings, :platform, :configdir, :name, :version, :directories, :license, :description, :vendor, :homepage

  def self.load_project(name, configdir, platform)
    projfile = File.join(configdir, "#{name}.rb")
    code = File.read(projfile)
    dsl = Vanagon::Project::DSL.new(name, platform)
    dsl.instance_eval(code)
    dsl._project
  rescue => e
    puts "Error loading project '#{name}' using '#{projfile}':"
    puts e
    puts e.backtrace.join("\n")
    raise e
  end

  def initialize(name, platform)
    @name = name
    @components = []
    @directories = []
    @settings = {}
    @version = "0.1.0"
    @platform = platform
  end

  def method_missing(method, *args)
    if @settings.has_key?(method)
      return @settings[method]
    end
  end

  def fetch_sources(workdir)
    @components.each do |component|
      component.get_source(workdir)
      unless component.patches.empty?
        patchdir = File.join(workdir, "patches")
        FileUtils.mkdir_p(patchdir)
        FileUtils.cp(component.patches, patchdir)
      end
    end
  end

  def get_service_files
    @components.map {|comp| comp.service_files }.flatten
  end

  def get_tarball_files
    files = []
    files.push prefix
    files.push sysconfdir
    files.push logdir
    files.push get_service_files
  end

  def pack_tarball_command
    tar_root = "#{@name}-#{@version}"
    ["mkdir -p '#{tar_root}'",
     %Q[tar -cf - #{get_tarball_files.join(" ")} | ( cd '#{tar_root}/'; tar xfp -)],
     %Q[tar -cf - #{tar_root}/ | gzip -9c > #{tar_root}.tar.gz]].join("\n\t")
  end

  def make_makefile(workdir)
    erb_file(File.join(VANAGON_ROOT, "templates/Makefile.erb"), File.join(workdir, "Makefile"))
  end

  # Return a list of the build_dependencies that are satisfied by an internal component
  def list_component_dependencies(component)
    component.build_requires.select {|dep| @components.map {|comp| comp.name}.include?(dep) }
  end

  def package_name
    @platform.package_name(self)
  end

  def generate_package
    @platform.generate_package(self)
  end

  def generate_packaging_artifacts(workdir)
    @platform.generate_packaging_artifacts(workdir, @name, binding)
  end
end
