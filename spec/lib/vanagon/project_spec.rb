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
  let (:dummy_platform_sysv) {
    plat = Vanagon::Platform::DSL.new('debian-6-i386')
    plat.instance_eval("platform 'debian-6-i386' do |plat|
                       plat.servicetype 'sysv'
                       plat.servicedir '/etc/init.d'
                       plat.defaultdir '/etc/default'
                    end")
    plat._platform
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

  describe '#get_preinstall_actions' do
    it "Collects the preinstall actions for the specified package state" do
      proj = Vanagon::Project.new('action-test', {})
      proj.get_preinstall_actions('upgrade')
      proj.get_preinstall_actions('install')
      expect(proj.get_preinstall_actions('install')).to be_instance_of(String)
    end
  end

  describe '#get_trigger_scripts' do
    it "Collects the install triggers for the project for the specified packing state" do
      proj = Vanagon::Project.new('action-test', {})
      expect(proj.get_trigger_scripts('install')).to eq({})
      expect(proj.get_trigger_scripts('upgrade')).to be_instance_of(Hash)
    end
    it 'fails with empty install trigger action' do
      proj = Vanagon::Project.new('action-test', {})
      expect { proj.get_trigger_scripts([]) }.to raise_error(Vanagon::Error)
    end
    it 'fails with incorrect install trigger action' do
      proj = Vanagon::Project.new('action-test', {})
      expect { proj.get_trigger_scripts('foo') }.to raise_error(Vanagon::Error)
    end
  end

  describe '#get_interest_triggers' do
    it "Collects the interest triggers for the project for the specified packaging state" do
      proj = Vanagon::Project.new('action-test', {})
      expect(proj.get_interest_triggers('install')).to eq([])
      expect(proj.get_interest_triggers('upgrade')).to be_instance_of(Array)
    end
    it 'fails with empty interest trigger action' do
      proj = Vanagon::Project.new('action-test', {})
      expect { proj.get_interest_triggers([]) }.to raise_error(Vanagon::Error)
    end
    it 'fails with incorrect interest trigger action' do
      proj = Vanagon::Project.new('action-test', {})
      expect { proj.get_interest_triggers('foo') }.to raise_error(Vanagon::Error)
    end
  end

  describe '#get_activate_triggers' do
    it "Collects the activate triggers for the project for the specified packaging state" do
      proj = Vanagon::Project.new('action-test', {})
      expect(proj.get_activate_triggers()).to be_instance_of(Array)
      expect(proj.get_activate_triggers()).to be_instance_of(Array)
    end
  end

  describe '#generate_dependencies_info' do
    before(:each) do
      @proj = Vanagon::Project.new('test-project', {})
    end

    it "returns a hash of components and their versions" do
      comp1 = Vanagon::Component.new('test-component1', {}, {})
      comp1.version = '1.0.0'
      comp2 = Vanagon::Component.new('test-component2', {}, {})
      comp2.version = '2.0.0'
      comp2.options[:ref] = '123abcd'
      comp3 = Vanagon::Component.new('test-component3', {}, {})
      @proj.components << comp1
      @proj.components << comp2
      @proj.components << comp3

      expect(@proj.generate_dependencies_info()).to eq({
        'test-component1' => { 'version' => '1.0.0' },
        'test-component2' => { 'version' => '2.0.0', 'ref' => '123abcd' },
        'test-component3' => {},
      })
    end
  end

  describe '#build_manifest_json' do
    before(:each) do
      class Vanagon
        class Project
          BUILD_TIME = '2017-07-10T13:34:25-07:00'
          VANAGON_VERSION = '0.0.0-rspec'
        end
      end

      @proj = Vanagon::Project.new('test-project', {})
    end

    it 'should generate a hash with the expected build metadata' do
      comp1 = Vanagon::Component.new('test-component1', {}, {})
      comp1.version = '1.0.0'
      @proj.components << comp1
      @proj.version = '123abcde'

      expect(@proj.build_manifest_json()).to eq({
        'packaging_type' => { 'vanagon' => '0.0.0-rspec' },
        'version' => '123abcde',
        'components' => { 'test-component1' => { 'version' => '1.0.0' } },
        'build_time' => '2017-07-10T13:34:25-07:00',
      })
    end
  end

  describe '#generate_package' do
    it "builds packages by default" do
      platform = Vanagon::Platform::DSL.new('el-7-x86_64')
      platform.instance_eval("platform 'el-7-x86_6' do |plat| end")
      proj = Vanagon::Project::DSL.new('test-fixture', platform._platform, [])
      expect(platform._platform).to receive(:generate_package) { ["# making a package"] }
      expect(proj._project.generate_package).to eq(["# making a package"])
    end

    it "builds packages and archives if configured for both" do
      platform = Vanagon::Platform::DSL.new('el-7-x86_64')
      platform.instance_eval("platform 'el-7-x86_6' do |plat| end")
      proj = Vanagon::Project::DSL.new('test-fixture', platform._platform, [])
      proj.generate_archives(true)
      expect(platform._platform).to receive(:generate_package) { ["# making a package"] }
      expect(platform._platform).to receive(:generate_compiled_archive) { ["# making an archive"] }
      expect(proj._project.generate_package).to eq(["# making a package", "# making an archive"])
    end

    it "can build only archives" do
      platform = Vanagon::Platform::DSL.new('el-7-x86_64')
      platform.instance_eval("platform 'el-7-x86_6' do |plat| end")
      proj = Vanagon::Project::DSL.new('test-fixture', platform._platform, [])
      proj.generate_archives(true)
      proj.generate_packages(false)
      expect(platform._platform).to receive(:generate_compiled_archive) { ["# making an archive"] }
      expect(proj._project.generate_package).to eq(["# making an archive"])
    end

    it "builds nothing if that's what you really want" do
      platform = Vanagon::Platform::DSL.new('el-7-x86_64')
      platform.instance_eval("platform 'el-7-x86_6' do |plat| end")
      proj = Vanagon::Project::DSL.new('test-fixture', platform._platform, [])
      proj.generate_packages(false)
      expect(proj._project.generate_package).to eq([])
    end
  end
end
