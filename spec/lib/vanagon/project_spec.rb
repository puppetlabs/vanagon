require 'vanagon/project'
require 'vanagon/driver'

describe 'Vanagon::Project' do
  let(:component) { double(Vanagon::Component) }
  let(:configdir) { '/a/b/c' }

  let(:project_block) {
    "project 'test-fixture' do |proj|
    proj.component 'some-component'
    end"
  }


  describe '#get_root_directories' do

    before do
      allow_any_instance_of(Vanagon::Project::DSL).to receive(:puts)
      allow(Vanagon::Driver).to receive(:configdir).and_return(configdir)
      allow(Vanagon::Component).to receive(:load_component).with('some-component', any_args).and_return(component)
    end

    let(:test_sets) do
      [
        {
          :directories => ["/opt/puppetlabs/bin", "/etc/puppetlabs", "/var/log/puppetlabs", "/etc/puppetlabs/puppet", "/opt/puppetlabs"],
          :results => ["/opt/puppetlabs", "/etc/puppetlabs", "/var/log/puppetlabs"],
        },
        {
          :directories => ["/opt/puppetlabs/bin", "/etc/puppetlabs", "/var/log/puppetlabs", "/etc/puppetlabs/puppet", "/opt/puppetlabs/lib"],
          :results => ["/opt/puppetlabs/bin", "/etc/puppetlabs", "/var/log/puppetlabs", "/opt/puppetlabs/lib"],
        },
      ]
    end

    it 'returns only the highest level directories' do
      test_sets.each do |set|
        expect(component).to receive(:directories).and_return([])
        proj = Vanagon::Project::DSL.new('test-fixture', {}, [])
        proj.instance_eval(project_block)
        set[:directories].each {|dir| proj.directory dir }
        expect(proj._project.get_root_directories.sort).to eq(set[:results].sort)
      end
    end
  end

  describe "#filter_component" do

    # All of the following tests should be run with one project level
    # component that isn't included in the build_deps of another component
    before(:each) do
      @proj = Vanagon::Project.new('test-fixture-with-comps', {})
      @not_included_comp = Vanagon::Component.new('test-fixture-not-included', {}, {})
      @proj.components << @not_included_comp
    end

    it "returns nil when given a component that doesn't exist" do
      expect(@proj.filter_component("fake")).to eq([])
    end

    it "returns only the component with no build deps" do
      comp = Vanagon::Component.new('test-fixture1', {}, {})
      @proj.components << comp
      expect(@proj.filter_component(comp.name)).to eq([comp])
    end

    it "returns component and one build dep" do
      comp1 = Vanagon::Component.new('test-fixture1', {}, {})
      comp2 = Vanagon::Component.new('test-fixture2', {}, {})
      comp1.build_requires << comp2.name
      @proj.components << comp1
      @proj.components << comp2
      expect(@proj.filter_component(comp1.name)).to eq([comp1, comp2])
    end

    it "returns only the component with build deps that are not components of the @project" do
      comp = Vanagon::Component.new('test-fixture1', {}, {})
      comp.build_requires << "fake-name"
      @proj.components << comp
      expect(@proj.filter_component(comp.name)).to eq([comp])
    end

    it "returns the component and build deps with both @project components and external build deps" do
      comp1 = Vanagon::Component.new('test-fixture1', {}, {})
      comp2 = Vanagon::Component.new('test-fixture2', {}, {})
      comp1.build_requires << comp2.name
      comp1.build_requires << "fake-name"
      @proj.components << comp1
      @proj.components << comp2
      expect(@proj.filter_component(comp1.name)).to eq([comp1, comp2])
    end

    it "returns the component and multiple build deps" do
      comp1 = Vanagon::Component.new('test-fixture1', {}, {})
      comp2 = Vanagon::Component.new('test-fixture2', {}, {})
      comp3 = Vanagon::Component.new('test-fixture3', {}, {})
      comp1.build_requires << comp2.name
      comp1.build_requires << comp3.name
      @proj.components << comp1
      @proj.components << comp2
      @proj.components << comp3
      expect(@proj.filter_component(comp1.name)).to eq([comp1, comp2, comp3])
    end

    it "returns the component and multiple build deps with external build deps" do
      comp1 = Vanagon::Component.new('test-fixture1', {}, {})
      comp2 = Vanagon::Component.new('test-fixture2', {}, {})
      comp3 = Vanagon::Component.new('test-fixture3', {}, {})
      comp1.build_requires << comp2.name
      comp1.build_requires << comp3.name
      comp1.build_requires << "another-fake-name"
      @proj.components << comp1
      @proj.components << comp2
      @proj.components << comp3
      expect(@proj.filter_component(comp1.name)).to eq([comp1, comp2, comp3])
    end
  end
end
