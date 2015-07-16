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

  let (:dummy_platform_sysv) {
    plat = Vanagon::Platform::DSL.new('debian-6-i386')
    plat.instance_eval("platform 'debian-6-i386' do |plat|
                       plat.servicetype 'sysv'
                       plat.servicedir '/etc/init.d'
                       plat.defaultdir '/etc/default'
                    end")
    plat._platform
  }

  let (:dummy_platform_systemd) {
    plat = Vanagon::Platform::DSL.new('el-7-x86_64')
    plat.instance_eval("platform 'el-7-x86_64' do |plat|
                       plat.servicetype 'systemd'
                       plat.servicedir '/usr/lib/systemd/system'
                       plat.defaultdir '/etc/default'
                    end")
    plat._platform
  }

  let (:dummy_platform_smf) {
    plat = Vanagon::Platform::DSL.new('debian-11-i386')
    plat.instance_eval("platform 'debian-11-i386' do |plat|
                       plat.servicetype 'smf'
                       plat.servicedir '/var/svc/manifest'
                       plat.defaultdir '/lib/svc/method'
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

  describe '#provides' do
    it 'adds the package provide to the list of provides' do
      comp = Vanagon::Component::DSL.new('provides-test', {}, {})
      comp.provides('thing1')
      comp.provides('thing2')
      expect(comp._component.provides.first.provide).to eq('thing1')
      expect(comp._component.provides.last.provide).to eq('thing2')
    end

    it 'supports versioned provides' do
      comp = Vanagon::Component::DSL.new('provides-test', {}, {})
      comp.provides('thing1', '1.2.3')
      expect(comp._component.provides.first.provide).to eq('thing1')
      expect(comp._component.provides.first.version).to eq('1.2.3')
    end
  end

  describe '#replaces' do
    it 'adds the package replacement to the list of replacements' do
      comp = Vanagon::Component::DSL.new('replaces-test', {}, {})
      comp.replaces('thing1')
      comp.replaces('thing2')
      expect(comp._component.replaces.first.replacement).to eq('thing1')
      expect(comp._component.replaces.last.replacement).to eq('thing2')
    end

    it 'supports versioned replaces' do
      comp = Vanagon::Component::DSL.new('replaces-test', {}, {})
      comp.replaces('thing1', '1.2.3')
      expect(comp._component.replaces.first.replacement).to eq('thing1')
      expect(comp._component.replaces.first.version).to eq('1.2.3')
    end
  end

  describe '#install_service' do
    it 'adds the correct command to the install for the component for sysv platforms' do
      comp = Vanagon::Component::DSL.new('service-test', {}, dummy_platform_sysv)
      comp.install_service('component-client.init', 'component-client.sysconfig')
      # Look for servicedir creation and copy
      expect(comp._component.install).to include("install -d '/etc/init.d'")
      expect(comp._component.install).to include("cp -p 'component-client.init' '/etc/init.d/service-test'")

      # Look for defaultdir creation and copy
      expect(comp._component.install).to include("install -d '/etc/default'")
      expect(comp._component.install).to include("cp -p 'component-client.sysconfig' '/etc/default/service-test'")

      # Look for files and configfiles
      expect(comp._component.configfiles).to include(Vanagon::Common::Pathname.new('/etc/default/service-test'))
      expect(comp._component.files).to include(Vanagon::Common::Pathname.new('/etc/init.d/service-test', '0755'))

      # The component should now have a service registered
      expect(comp._component.service.name).to eq('service-test')
    end

    it 'adds the correct command to the install for the component for systemd platforms' do
      comp = Vanagon::Component::DSL.new('service-test', {}, dummy_platform_systemd)
      comp.install_service('component-client.service', 'component-client.sysconfig')
      # Look for servicedir creation and copy
      expect(comp._component.install).to include("install -d '/usr/lib/systemd/system'")
      expect(comp._component.install).to include("cp -p 'component-client.service' '/usr/lib/systemd/system/service-test.service'")

      # Look for defaultdir creation and copy
      expect(comp._component.install).to include("install -d '/etc/default'")
      expect(comp._component.install).to include("cp -p 'component-client.sysconfig' '/etc/default/service-test'")

      # Look for files and configfiles
      expect(comp._component.configfiles).to include(Vanagon::Common::Pathname.new('/etc/default/service-test'))
      expect(comp._component.files).to include(Vanagon::Common::Pathname.new('/usr/lib/systemd/system/service-test.service', '0644'))

      # The component should now have a service registered
      expect(comp._component.service.name).to eq('service-test')
    end

    it 'adds the correct command to the install for smf services using a service_type' do
      comp = Vanagon::Component::DSL.new('service-test', {}, dummy_platform_smf)
      comp.install_service('service.xml', 'service-default-file', service_type: 'network')
      # Look for servicedir creation and copy
      expect(comp._component.install).to include("install -d '/var/svc/manifest/network'")
      expect(comp._component.install).to include("cp -p 'service.xml' '/var/svc/manifest/network/service-test.xml'")

      # Look for defaultdir creation and copy
      expect(comp._component.install).to include("install -d '/lib/svc/method'")
      expect(comp._component.install).to include("cp -p 'service-default-file' '/lib/svc/method/service-test'")

      # Look for files and configfiles
      expect(comp._component.configfiles).to include(Vanagon::Common::Pathname.new('/lib/svc/method/service-test'))
      expect(comp._component.files).to include(Vanagon::Common::Pathname.new('/var/svc/manifest/network/service-test.xml', '0644'))

      # The component should now have a service registered
      expect(comp._component.service.name).to eq('service-test')
    end

    it 'adds the correct command to the install for smf services' do
      comp = Vanagon::Component::DSL.new('service-test', {}, dummy_platform_smf)
      comp.install_service('service.xml', 'service-default-file')
      # Look for servicedir creation and copy
      expect(comp._component.install).to include("install -d '/var/svc/manifest'")
      expect(comp._component.install).to include("cp -p 'service.xml' '/var/svc/manifest/service-test.xml'")

      # Look for defaultdir creation and copy
      expect(comp._component.install).to include("install -d '/lib/svc/method'")
      expect(comp._component.install).to include("cp -p 'service-default-file' '/lib/svc/method/service-test'")

      # Look for files and configfiles
      expect(comp._component.configfiles).to include(Vanagon::Common::Pathname.new('/lib/svc/method/service-test'))
      expect(comp._component.files).to include(Vanagon::Common::Pathname.new('/var/svc/manifest/service-test.xml', '0644'))

      # The component should now have a service registered
      expect(comp._component.service.name).to eq('service-test')
    end
  end

  describe '#install_file' do
    it 'adds the correct commands to the install to copy the file' do
      comp = Vanagon::Component::DSL.new('install-file-test', {}, {})
      comp.install_file('thing1', 'place/to/put/thing1')
      expect(comp._component.install).to include("install -d 'place/to/put'")
      expect(comp._component.install).to include("cp -p 'thing1' 'place/to/put/thing1'")
    end

    it 'adds an owner and group to the installation' do
      comp = Vanagon::Component::DSL.new('install-file-test', {}, {})
      comp.install_file('thing1', 'place/to/put/thing1', owner: 'bob', group: 'timmy', mode: '0022')
      expect(comp._component.install).to include("install -d 'place/to/put'")
      expect(comp._component.install).to include("cp -p 'thing1' 'place/to/put/thing1'")
      expect(comp._component.files).to include(Vanagon::Common::Pathname.new('place/to/put/thing1', '0022', 'bob', 'timmy'))
    end
  end

  describe 'configfile handling' do
    let(:platform) { double(Vanagon::Platform) }

    describe 'on anything but solaris 10' do
      before do
        allow(platform).to receive(:name).and_return('debian-8-amd64')
      end

      describe '#configfile' do
        it 'adds the file to the configfiles list' do
          comp = Vanagon::Component::DSL.new('config-file-test', {}, platform)
          comp.configfile('/place/to/put/thing1')
          expect(comp._component.configfiles).to include(Vanagon::Common::Pathname.new('/place/to/put/thing1'))
        end
      end

      describe '#install_configfile' do
        it 'adds the commands to install the configfile' do
          comp = Vanagon::Component::DSL.new('install-config-file-test', {}, platform)
          comp.install_configfile('thing1', 'place/to/put/thing1')
          expect(comp._component.install).to include("install -d 'place/to/put'")
          expect(comp._component.install).to include("cp -p 'thing1' 'place/to/put/thing1'")
        end

        it 'adds the file to the configfiles list' do
          comp = Vanagon::Component::DSL.new('install-config-file-test', {}, platform)
          comp.install_configfile('thing1', 'place/to/put/thing1')
          expect(comp._component.configfiles).to include(Vanagon::Common::Pathname.new('place/to/put/thing1'))
        end
      end
    end

    describe 'on solaris 10, do something terrible' do
      before do
        allow(platform).to receive(:name).and_return('solaris-10-x86_64')
      end

      describe '#configfile' do
        it 'adds the file to the configfiles list' do
          comp = Vanagon::Component::DSL.new('config-file-test', {}, platform)
          comp.configfile('/place/to/put/thing1')
          expect(comp._component.configfiles).to include(Vanagon::Common::Pathname.new('/place/to/put/thing1.pristine'))
        end
      end

      describe '#install_configfile' do
        it 'adds the commands to install the configfile' do
          comp = Vanagon::Component::DSL.new('install-config-file-test', {}, platform)
          comp.install_configfile('thing1', 'place/to/put/thing1')
          expect(comp._component.install).to include("install -d 'place/to/put'")
          expect(comp._component.install).to include("cp -p 'thing1' 'place/to/put/thing1'")
        end

        it 'adds the file to the configfiles list' do
          comp = Vanagon::Component::DSL.new('install-config-file-test', {}, platform)
          comp.install_configfile('thing1', 'place/to/put/thing1')
          expect(comp._component.configfiles).to include(Vanagon::Common::Pathname.new('place/to/put/thing1.pristine'))
        end
      end
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

  describe '#environment' do
    it 'adds an override to the environment for a component' do
      comp = Vanagon::Component::DSL.new('env-test', {}, {})
      comp.environment({'PATH' => '/usr/local/bin'})
      expect(comp._component.environment).to eq({'PATH' => '/usr/local/bin'})
    end

    it 'merges against the existing environment' do
      comp = Vanagon::Component::DSL.new('env-test', {}, {})
      comp.environment({'PATH' => '/usr/local/bin'})
      comp.environment({'PATH' => '/usr/bin'})
      comp.environment({'CFLAGS' => '-I /usr/local/bin'})
      expect(comp._component.environment).to eq({'PATH' => '/usr/bin', 'CFLAGS' => '-I /usr/local/bin'})
    end
  end

  describe '#directory' do
    it 'adds a directory with the desired path to the directory collection for the component' do
      comp = Vanagon::Component::DSL.new('directory-test', {}, {})
      comp.directory('/a/b/c')
      expect(comp._component.directories).to include(Vanagon::Common::Pathname.new('/a/b/c'))
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
