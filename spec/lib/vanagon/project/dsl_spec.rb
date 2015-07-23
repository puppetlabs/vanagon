require 'vanagon/project/dsl'
require 'vanagon/driver'
require 'vanagon/common'

describe 'Vanagon::Project::DSL' do
  let (:project_block) {
"project 'test-fixture' do |proj|
end" }
  let (:configdir) { '/a/b/c' }

  describe '#version_from_git' do
    it 'sets the version based on the git describe' do
      expect(Vanagon::Driver).to receive(:configdir).and_return(configdir)
      proj = Vanagon::Project::DSL.new('test-fixture', {})
      proj.instance_eval(project_block)
      expect(Vanagon::Utilities).to receive(:git_version).with(File.expand_path('..', configdir)).and_return('1.2.3-1234')
      proj.version_from_git
      expect(proj._project.version).to eq('1.2.3.1234')
    end
  end

  describe '#directory' do
    it 'adds a directory to the list of directories' do
      proj = Vanagon::Project::DSL.new('test-fixture', {})
      proj.instance_eval(project_block)
      proj.directory('/a/b/c/d', mode: '0755')
      expect(proj._project.directories).to include(Vanagon::Common::Pathname.new('/a/b/c/d', '0755'))
    end
  end

  describe '#user' do
    it 'sets a user for the project' do
      proj = Vanagon::Project::DSL.new('test-fixture', {})
      proj.instance_eval(project_block)
      proj.user('test-user')
      expect(proj._project.user).to eq(Vanagon::Common::User.new('test-user'))
    end
  end

  describe '#target_repo' do
    it 'sets the target_repo for the project' do
      proj = Vanagon::Project::DSL.new('test-fixture', {})
      proj.instance_eval(project_block)
      proj.target_repo "pc1"
      expect(proj._project.repo).to eq("pc1")
    end
  end

  describe '#noarch' do
    it 'sets noarch on the project to true' do
      proj = Vanagon::Project::DSL.new('test-fixture', {})
      proj.instance_eval(project_block)
      proj.noarch
      expect(proj._project.noarch).to eq(true)
    end
  end

  describe '#identifier' do
    it 'sets the identifier for the project' do
      proj = Vanagon::Project::DSL.new('test-fixture', {})
      proj.instance_eval(project_block)
      proj.identifier "com.example"
      expect(proj._project.identifier).to eq("com.example")
    end
  end

  describe '#cleanup_during_build' do
    it 'sets @cleanup to true' do
      proj = Vanagon::Project::DSL.new('test-fixture', {})
      proj.instance_eval(project_block)
      proj.cleanup_during_build
      expect(proj._project.cleanup).to eq(true)
    end

    it 'defaults to nil' do
      proj = Vanagon::Project::DSL.new('test-fixture', {})
      proj.instance_eval(project_block)
      expect(proj._project.cleanup).to be_nil
    end
  end

  describe "#write_version_file" do
    let(:version_file) { '/opt/puppetlabs/puppet/VERSION' }

    it 'sets version_file for the project' do
      proj = Vanagon::Project::DSL.new('test-fixture', {})
      proj.instance_eval(project_block)
      proj.write_version_file(version_file)
      expect(proj._project.version_file.path).to eq(version_file)
    end
  end

  describe "#release" do
    it 'sets the release for the project' do
      proj = Vanagon::Project::DSL.new('test-fixture', {})
      proj.instance_eval(project_block)
      proj.release '12'
      expect(proj._project.release).to eq('12')
    end

    it 'defaults to 1' do
      proj = Vanagon::Project::DSL.new('test-fixture', {})
      proj.instance_eval(project_block)
      expect(proj._project.release).to eq('1')
    end
  end

  describe "#component" do
    let(:project_block) {
"project 'test-fixture' do |proj|
  proj.component 'some-component'
end"
    }

    let(:component) { double(Vanagon::Component) }

    before do
      allow_any_instance_of(Vanagon::Project::DSL).to receive(:puts)
      allow(Vanagon::Driver).to receive(:configdir).and_return(configdir)
      allow(Vanagon::Component).to receive(:load_component).with('some-component', any_args).and_return(component)
    end

    it 'stores the component in the project if the included components set is empty' do
      proj = Vanagon::Project::DSL.new('test-fixture', {}, [])
      proj.instance_eval(project_block)
      expect(proj._project.components).to include(component)
    end

    it 'stores the component in the project if the component name is listed in the included components set' do
      proj = Vanagon::Project::DSL.new('test-fixture', {}, ['some-component'])
      proj.instance_eval(project_block)
      expect(proj._project.components).to include(component)
    end

    it 'does not store the component if the included components set is not empty and does not include the component name' do
      proj = Vanagon::Project::DSL.new('test-fixture', {}, ['some-different-component'])
      proj.instance_eval(project_block)
      expect(proj._project.components).to_not include(component)
    end
  end
end
