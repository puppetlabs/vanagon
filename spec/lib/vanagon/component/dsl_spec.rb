require 'vanagon/component/dsl'
require 'vanagon/common'
require 'json'

describe 'Vanagon::Component::DSL' do
  let (:component_block) {
"component 'test-fixture' do |pkg, settings, platform|
  pkg.load_from_json('spec/fixures/component/test-fixture.json')
end" }

  let (:invalid_component_block) {
"component 'test-fixture' do |pkg, settings, platform|
  pkg.load_from_json('spec/fixures/component/invalid-test-fixture.json')
end" }

  let (:dummy_platform) {
    plat = Vanagon::Platform::DSL.new('debian-6-i386')
    plat.instance_eval("platform 'debian-6-i386' do |plat|
                       plat.servicetype 'sysv'
                       plat.servicedir '/etc/init.d'
                       plat.defaultdir '/etc/default'
                    end")
    plat._platform
  }

  describe '#load_from_json' do
    it "sets the ref and url based on the json fixture" do
      comp = Vanagon::Component::DSL.new('test-fixture', {}, {})
      comp.instance_eval(component_block)
      expect(comp._component.options[:ref]).to eq('3.7.3')
      expect(comp._component.url).to eq('git@github.com:puppetlabs/puppet')
    end

    it "raises an error on invalid methods/attributes in the json" do
      comp = Vanagon::Component::DSL.new('test-fixture', {}, {})
      expect { comp.instance_eval(invalid_component_block) }.to raise_error(RuntimeError)
    end
  end

  describe '#configure' do
    it 'sets configure to the value if configure is empty' do
      comp = Vanagon::Component::DSL.new('configure-test', {}, {})
      comp.configure { './configure' }
      expect(comp._component.configure).to eq(['./configure'])
    end

    it 'appends to the existing configure if not empty' do
      comp = Vanagon::Component::DSL.new('configure-test', {}, {})
      comp.configure { './configure' }
      comp.configure { './test' }
      expect(comp._component.configure).to eq(['./configure', './test'])
    end
  end

  describe '#build' do
    it 'sets build to the value if build is empty' do
      comp = Vanagon::Component::DSL.new('build-test', {}, {})
      comp.build { './build' }
      expect(comp._component.build).to eq(['./build'])
    end

    it 'appends to the existing build if not empty' do
      comp = Vanagon::Component::DSL.new('build-test', {}, {})
      comp.build { './build' }
      comp.build { './test' }
      expect(comp._component.build).to eq(['./build', './test'])
    end
  end

  describe '#install' do
    it 'sets install to the value if install is empty' do
      comp = Vanagon::Component::DSL.new('install-test', {}, {})
      comp.install { './install' }
      expect(comp._component.install).to eq(['./install'])
    end

    it 'appends to the existing install if not empty' do
      comp = Vanagon::Component::DSL.new('install-test', {}, {})
      comp.install { './install' }
      comp.install { './test' }
      expect(comp._component.install).to eq(['./install', './test'])
    end
  end

  describe '#apply_patch' do
    it 'adds the patch to the list of patches' do
      comp = Vanagon::Component::DSL.new('patch-test', {}, {})
      comp.apply_patch('patch_file1')
      comp.apply_patch('patch_file2')
      expect(comp._component.patches).to include('patch_file1')
      expect(comp._component.patches).to include('patch_file2')
    end
  end

  describe '#build_requires' do
    it 'adds the build requirement to the list of build requirements' do
      comp = Vanagon::Component::DSL.new('buildreq-test', {}, {})
      comp.build_requires('library1')
      comp.build_requires('library2')
      expect(comp._component.build_requires).to include('library1')
      expect(comp._component.build_requires).to include('library2')
    end
  end

  describe '#requires' do
    it 'adds the runtime requirement to the list of requirements' do
      comp = Vanagon::Component::DSL.new('requires-test', {}, {})
      comp.requires('library1')
      comp.requires('library2')
      expect(comp._component.requires).to include('library1')
      expect(comp._component.requires).to include('library2')
    end
  end

  describe '#install_service' do
    it 'adds the correct command to the install for the component' do
      comp = Vanagon::Component::DSL.new('service-test', {}, dummy_platform)
      comp.install_service('component-client.init', 'component-client.sysconfig')
      # Look for servicedir creation and copy
      expect(comp._component.install).to include("install -d '/etc/init.d'")
      expect(comp._component.install).to include("cp -p 'component-client.init' '/etc/init.d/service-test'")

      # Look for defaultdir creation and copy
      expect(comp._component.install).to include("install -d '/etc/default'")
      expect(comp._component.install).to include("cp -p 'component-client.sysconfig' '/etc/default/service-test'")

      # The component should now have a service registered
      expect(comp._component.service).to eq('service-test')
    end
  end

  describe '#install_file' do
    it 'adds the correct commands to the install to copy the file' do
      comp = Vanagon::Component::DSL.new('install-file-test', {}, {})
      comp.install_file('thing1', 'place/to/put/thing1')
      expect(comp._component.install).to include("install -d 'place/to/put'")
      expect(comp._component.install).to include("cp -p 'thing1' 'place/to/put/thing1'")
    end
  end

  describe '#configfile' do
    it 'adds the file to the configfiles list' do
      comp = Vanagon::Component::DSL.new('config-file-test', {}, {})
      comp.configfile('/place/to/put/thing1')
      expect(comp._component.configfiles).to include('/place/to/put/thing1')
    end
  end

  describe '#install_configfile' do
    it 'adds the commands to install the configfile' do
      comp = Vanagon::Component::DSL.new('install-config-file-test', {}, {})
      comp.install_configfile('thing1', 'place/to/put/thing1')
      expect(comp._component.install).to include("install -d 'place/to/put'")
      expect(comp._component.install).to include("cp -p 'thing1' 'place/to/put/thing1'")
    end

    it 'adds the file to the configfiles list' do
      comp = Vanagon::Component::DSL.new('install-config-file-test', {}, {})
      comp.install_configfile('thing1', 'place/to/put/thing1')
      expect(comp._component.configfiles).to include('place/to/put/thing1')
    end
  end

  describe '#link' do
    it 'adds the correct command to the install for the component' do
      comp = Vanagon::Component::DSL.new('link-test', {}, {})
      comp.link('link-source', '/place/to/put/things')
      expect(comp._component.install).to include("install -d '/place/to/put'")
      expect(comp._component.install).to include("ln -s 'link-source' '/place/to/put/things'")
    end
  end

  describe '#directory' do
    it 'adds a directory with the desired path to the directory collection for the component' do
      comp = Vanagon::Component::DSL.new('directory-test', {}, {})
      comp.directory('/a/b/c')
      expect(comp._component.directories.first).to eq(Vanagon::Common::Pathname.new('/a/b/c'))
    end

    it 'adds a directory with the desired mode to the directory collection for the component' do
      comp = Vanagon::Component::DSL.new('directory-test', {}, {})
      comp.directory('/a/b/c', mode: '0755')
      expect(comp._component.directories.first).to eq(Vanagon::Common::Pathname.new('/a/b/c', '0755'))
    end

    it 'adds a directory with the desired owner to the directory collection for the component' do
      comp = Vanagon::Component::DSL.new('directory-test', {}, {})
      comp.directory('/a/b/c', owner: 'olivia')
      expect(comp._component.directories.first).to eq(Vanagon::Common::Pathname.new('/a/b/c', nil, 'olivia'))
    end

    it 'adds a directory with the desired group to the directory collection for the component' do
      comp = Vanagon::Component::DSL.new('directory-test', {}, {})
      comp.directory('/a/b/c', group: 'release-engineering')
      expect(comp._component.directories.first).to eq(Vanagon::Common::Pathname.new('/a/b/c', nil, nil, 'release-engineering'))
    end

    it 'adds a directory with the desired attributes to the directory collection for the component' do
      comp = Vanagon::Component::DSL.new('directory-test', {}, {})
      comp.directory('/a/b/c', mode: '0400', owner: 'olivia', group: 'release-engineering')
      expect(comp._component.directories.first).to eq(Vanagon::Common::Pathname.new('/a/b/c', '0400', 'olivia', 'release-engineering'))
    end
  end
end
