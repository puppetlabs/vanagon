require 'vanagon/project'
require 'vanagon/project/dsl'
require 'vanagon/platform'
require 'vanagon/platform/dsl'
require 'vanagon/component'
require 'vanagon/utilities'
require 'tmpdir'

class Vanagon::Builder
  include Vanagon::Utilities
  attr_accessor :platform, :project, :target, :workdir

  # Future options: configdir, backend for virtualization

  def initialize(platform, project, configdir)
    @platform_name = platform
    @project_name = project
    @workdir = Dir.mktmpdir
    @configdir = configdir
  end

  def load_platform
    @platform = Vanagon::Platform.load_platform(@platform_name, File.join(@configdir, "platforms"))
  end

  def load_project
    @project = Vanagon::Project.load_project(@project_name, File.join(@configdir, "projects"), @platform)
  end

  def cleanup_workdir
    FileUtils.rm_rf(@workdir)
  end

  def get_target
    target = curl("http://vcloud/vm/#{@platform.vcloud_name}", "POST")
    if target and target["ok"]
      return target[@platform.vcloud_name]["hostname"]
    else
      puts "something went wrong, maybe the pool for #{@platform.vcloud_name} is empty?"
      return false
    end
  end

  def provision_template(target)
    script = @platform.provisioning
    remote_ssh_command(target, script)
  end

  def install_build_dependencies(target)
    remote_ssh_command(target, "#{@platform.build_dependencies} #{@project.components.map {|comp| comp.build_dependencies.join(' ')}.join(' ')}")
  end

  def ship_workdir_to(target)
    rsync_to("#{@workdir}/*", target, "~/", [])
  end

  def build_artifact_on(target)
    remote_ssh_command(target, "time #{@platform.make}")
  end

  def retrieve_built_artifact_from(target)
    rsync_from("output/*", target, "output")
  end

  def teardown_template(host)
    target = curl("http://vcloud/vm/#{host}", "DELETE")
    if target and target["ok"]
      puts "'#{host}' has been destroyed"
      return true
    else
      puts "something went wrong"
      return false
    end
  end

  def run(target = nil, preserve = false)
    begin
      load_platform
      load_project

      unless target
        target = get_target
      end

      login = "root@#{target}"

      puts "Target is #{target}"

      # All about the target
      FileUtils.mkdir_p("output")
      provision_template(login)
      install_build_dependencies(login)
      @project.fetch_sources(@workdir)
      @project.make_makefile(@workdir)
      @project.generate_packaging_artifacts(@workdir)
      ship_workdir_to(login)
      build_artifact_on(login)
      retrieve_built_artifact_from(login)
      teardown_template(target) unless preserve
      cleanup_workdir unless preserve
    rescue => e
      puts e
      puts e.backtrace.join("\n")
      raise e
    end
  end

end
