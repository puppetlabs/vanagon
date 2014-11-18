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
    compfile = File.join(Vanagon::Driver.configdir, "components", "#{name}.rb")
    if File.exists?(compfile)
      code = File.read(compfile)
      component = Vanagon::Component.new
      component.settings = @project.settings
      component.platform = @project.platform
      begin
        component.instance_eval(code)
      rescue => e
        puts e
        puts e.backtrace.join("\n")
        raise e
      end
      # We only append if name is actually set because that is an easy way to see if the component applies to the current platform.
      @project.components << component if component.name
    else
      STDERR.puts "Could not find a file describing platform: '#{name}'. Was looking for '#{compfile}'."
    end

  end
end
