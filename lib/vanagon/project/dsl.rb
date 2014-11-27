require 'vanagon/project'

class Vanagon::Project::DSL

  def initialize(name, platform)
    @name = name
    @project = Vanagon::Project.new(@name, platform)
  end

  def project(name, &block)
    block.call(self)
  end

  def _project
    @project
  end


  # Project attributes and DSL methods defined below
  #
  #
  def method_missing(method, *args)
    if @project.settings.has_key?(method)
      return @project.settings[method]
    end
  end

  def setting(name, value)
    @project.settings[name] = value
  end

  def description(descr)
    @project.description = descr
  end

  def homepage(page)
    @project.homepage = page
  end

  def version(ver)
    @project.version = ver
  end

  def vendor(vend)
    @project.vendor = vend
  end

  def directory(dir)
    @project.directories << dir
  end

  def license(lic)
    @project.license = lic
  end

  def component(name)
    puts "Loading #{name}"
    component = Vanagon::Component.load_component(name, File.join(Vanagon::Driver.configdir, "components"), @project.settings, @project.platform)
    @project.components << component if component.url
  end
end
