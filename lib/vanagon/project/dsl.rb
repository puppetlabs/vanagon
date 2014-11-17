require 'vanagon/project'

class Vanagon::Project::DSL

  def initialize(name, platform)
    @name = name
    @project = Vanagon::Project.new(@name, platform)
  end

  def project(name, &block)
    block.call(@project, @project.settings)
  end

  def _project
    @project
  end
end
