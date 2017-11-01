require 'vanagon/component/dsl'
require 'vanagon/common'
require 'json'

describe 'Vanagon::Component::DSL' do
  let (:component_block) {
"component 'test-fixture' do |pkg, settings, platform|
  pkg.load_from_json('spec/fixtures/component/test-fixture.json')
end" }

  let (:invalid_component_block) {
"component 'test-fixture' do |pkg, settings, platform|
  pkg.load_from_json('spec/fixtures/component/invalid-test-fixture.json')
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

  let (:dummy_platform_aix) {
    plat = Vanagon::Platform::DSL.new('aix-7.1-ppc')
    plat.instance_eval("platform 'aix-7.1-ppc' do |plat|
                       plat.servicetype 'aix'
                       plat.servicedir '/etc/rc.d'
                       plat.defaultdir '/etc/rc.d'
                    end")
    plat._platform
  }

  let(:platform) { double(Vanagon::Platform) }

  # These TOTALLY VALID sums are computed against a passage from
  # "The Hitchhiker's Guide to the Galaxy", by Douglas Adams (1979).
  # Specifically, about humans assuming they are smarter than dolphins
  # for exactly the same reason dolphins assume they are smart than
  # humans. This seemed appropriate after the checksum refactoring
  # broke all checksums and we discovered that they were untested.
  let(:dummy_md5_sum) { "08b55473b59d2b43af8b61c9512ef5c6" }
  let(:dummy_sha1_sum) { "fdaa03c3f506d7b71635f2c32dfd41b0cc8b904f" }
  let(:dummy_sha256_sum) { "fd9c922702eb2e2fb26376c959753f0fc167bb6bc99c79262fcff7bcc8b34be1" }
  let(:dummy_sha512_sum) { "8feda1e9896be618dd6c65120d10afafce93888df8569c598f52285083c23befd1477da5741939d4eae042f822e45ca2e45d8d4d18cf9224b7acaf71d883841e" }
  let(:dummy_md5_url) { "http://example.com/example.tar.gz.md5" }
  let(:dummy_sha1_url) { "http://example.com/example.tar.gz.sha1" }
  let(:dummy_sha256_url) { "http://example.com/example.tar.gz.sha256" }
  let(:dummy_sha512_url) { "http://example.com/example.tar.gz.sha512" }

  before do
    allow(platform).to receive(:install).and_return('install')
    allow(platform).to receive(:copy).and_return('cp')
    allow(platform).to receive(:is_windows?).and_return(false)
  end

  describe "#md5sum" do
    it "sets a checksum value & type correctly" do
      comp = Vanagon::Component::DSL.new('test-fixture', {}, {})
      comp.md5sum(dummy_md5_sum)

      expect(comp._component.options[:sum]).to eq(dummy_md5_sum)
      expect(comp._component.options[:sum_type]).to eq('md5')
    end
    it "sets md5 url and type correctly" do
      comp = Vanagon::Component::DSL.new('test-fixture', {}, {})
      comp.md5sum(dummy_md5_url)

      expect(comp._component.options[:sum]).to eq(dummy_md5_url)
      expect(comp._component.options[:sum_type]).to eq('md5')
    end
  end

  describe "#sha1sum" do
    it "sets a checksum value & type correctly" do
      comp = Vanagon::Component::DSL.new('test-fixture', {}, {})
      comp.sha1sum(dummy_sha1_sum)

      expect(comp._component.options[:sum]).to eq(dummy_sha1_sum)
      expect(comp._component.options[:sum_type]).to eq('sha1')
    end
    it "sets sha1 url and type correctly" do
      comp = Vanagon::Component::DSL.new('test-fixture', {}, {})
      comp.sha1sum(dummy_sha1_url)

      expect(comp._component.options[:sum]).to eq(dummy_sha1_url)
      expect(comp._component.options[:sum_type]).to eq('sha1')
    end
  end

  describe "#sha256sum" do
    it "sets a checksum value & type correctly" do
      comp = Vanagon::Component::DSL.new('test-fixture', {}, {})
      comp.sha256sum(dummy_sha256_sum)

      expect(comp._component.options[:sum]).to eq(dummy_sha256_sum)
      expect(comp._component.options[:sum_type]).to eq('sha256')
    end
    it "sets sha256 url and type correctly" do
      comp = Vanagon::Component::DSL.new('test-fixture', {}, {})
      comp.sha256sum(dummy_sha256_url)

      expect(comp._component.options[:sum]).to eq(dummy_sha256_url)
      expect(comp._component.options[:sum_type]).to eq('sha256')
    end
  end

  describe "#sha512sum" do
    it "sets a checksum value & type correctly" do
      comp = Vanagon::Component::DSL.new('test-fixture', {}, {})
      comp.sha512sum(dummy_sha512_sum)

      expect(comp._component.options[:sum]).to eq(dummy_sha512_sum)
      expect(comp._component.options[:sum_type]).to eq('sha512')
    end
    it "sets sha512 url and type correctly" do
      comp = Vanagon::Component::DSL.new('test-fixture', {}, {})
      comp.sha512sum(dummy_sha512_url)

      expect(comp._component.options[:sum]).to eq(dummy_sha512_url)
      expect(comp._component.options[:sum_type]).to eq('sha512')
    end
  end

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

  describe '#check' do
    it 'sets check to the value if check is empty' do
      comp = Vanagon::Component::DSL.new('check-test', {}, {})
      comp.check { './check' }
      expect(comp._component.check).to eq(['./check'])
    end

    it 'appends to the existing check if not empty' do
      comp = Vanagon::Component::DSL.new('check-test', {}, {})
      comp.check { 'make test' }
      comp.check { 'make cpplint' }
      expect(comp._component.check).to eq(['make test', 'make cpplint'])
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
      expect(comp._component.patches.count).to eq 2
      expect(comp._component.patches.first.path).to eq 'patch_file1'
      expect(comp._component.patches.last.path).to eq 'patch_file2'
    end

    it 'can specify strip and fuzz' do
      comp = Vanagon::Component::DSL.new('patch-test', {}, {})
      # This patch must be amazing
      comp.apply_patch('patch_file1', fuzz: 12, strip: 1000000)
      expect(comp._component.patches.count).to eq 1
      expect(comp._component.patches.first.path).to eq 'patch_file1'
      expect(comp._component.patches.first.fuzz).to eq 12
      expect(comp._component.patches.first.strip).to eq 1000000
    end

    it 'can specify a directory where the patch should be applied' do
      comp = Vanagon::Component::DSL.new('patch-test', {}, {})
      comp.apply_patch('patch_file1', destination: 'random/install/directory')
      expect(comp._component.patches.count).to eq 1
      expect(comp._component.patches.first.path).to eq 'patch_file1'
      expect(comp._component.patches.first.destination).to eq 'random/install/directory'
    end

    it 'can specify when to try to apply the patch' do
      comp = Vanagon::Component::DSL.new('patch-test', {}, {})
      comp.apply_patch('patch_file1', after: 'install')
      expect(comp._component.patches.count).to eq 1
      expect(comp._component.patches.first.path).to eq 'patch_file1'
      expect(comp._component.patches.first.after).to eq 'install'
    end

    it 'will default the patch timing to after the source is unpacked' do
      comp = Vanagon::Component::DSL.new('patch-test', {}, {})
      comp.apply_patch('patch_file1')
      expect(comp._component.patches.count).to eq 1
      expect(comp._component.patches.first.path).to eq 'patch_file1'
      expect(comp._component.patches.first.after).to eq 'unpack'
    end

    it 'will fail if the user wants to install the patch at an unsupported step' do
      comp = Vanagon::Component::DSL.new('patch-test', {}, {})
      expect { comp.apply_patch('patch_file1', after: 'delivery') }.to raise_error(Vanagon::Error)
    end

    it 'can specify a directory where the patch should be applied' do
      comp = Vanagon::Component::DSL.new('patch-test', {}, {})
      comp.apply_patch('patch_file1', destination: 'random/install/directory')
      expect(comp._component.patches.count).to eq 1
      expect(comp._component.patches.first.path).to eq 'patch_file1'
      expect(comp._component.patches.first.destination).to eq 'random/install/directory'
    end

    it 'can specify when to try to apply the patch' do
      comp = Vanagon::Component::DSL.new('patch-test', {}, {})
      comp.apply_patch('patch_file1', after: 'install')
      expect(comp._component.patches.count).to eq 1
      expect(comp._component.patches.first.path).to eq 'patch_file1'
      expect(comp._component.patches.first.after).to eq 'install'
    end

    it 'will default the patch timing to after the source is unpacked' do
      comp = Vanagon::Component::DSL.new('patch-test', {}, {})
      comp.apply_patch('patch_file1')
      expect(comp._component.patches.count).to eq 1
      expect(comp._component.patches.first.path).to eq 'patch_file1'
      expect(comp._component.patches.first.after).to eq 'unpack'
    end

    it 'will fail if the user wants to install the patch at an unsupported step' do
      comp = Vanagon::Component::DSL.new('patch-test', {}, {})
      expect { comp.apply_patch('patch_file1', after: 'delivery') }.to raise_error(Vanagon::Error)
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

  describe '#conflicts' do
    it 'adds the package conflict to the list of conflicts' do
      comp = Vanagon::Component::DSL.new('conflicts-test', {}, {})
      comp.conflicts('thing1')
      comp.conflicts('thing2')
      expect(comp._component.conflicts.first.pkgname).to eq('thing1')
      expect(comp._component.conflicts.last.pkgname).to eq('thing2')
    end

    it 'supports versioned conflicts' do
      comp = Vanagon::Component::DSL.new('conflicts-test', {}, {})
      comp.conflicts('thing1', '1.2.3')
      expect(comp._component.conflicts.first.pkgname).to eq('thing1')
      expect(comp._component.conflicts.first.version).to eq('1.2.3')
    end
  end

  describe '#add_actions' do
    it 'adds the correct preinstall action to the component' do
      comp = Vanagon::Component::DSL.new('action-test', {}, dummy_platform_sysv)
      comp.add_preinstall_action(['install', 'upgrade'], ['chkconfig --list', '/bin/true'])
      comp.add_preinstall_action('install', 'echo "hello, world"')
      expect(comp._component.preinstall_actions.count).to eq(2)
      expect(comp._component.preinstall_actions.first.scripts.count).to eq(2)
      expect(comp._component.preinstall_actions.first.pkg_state.count).to eq(2)
      expect(comp._component.preinstall_actions.first.pkg_state.first).to eq('install')
      expect(comp._component.preinstall_actions.first.pkg_state.last).to eq('upgrade')
      expect(comp._component.preinstall_actions.first.scripts.first).to eq('chkconfig --list')
      expect(comp._component.preinstall_actions.first.scripts.last).to eq('/bin/true')

      expect(comp._component.preinstall_actions.last.scripts.count).to eq(1)
      expect(comp._component.preinstall_actions.last.pkg_state.count).to eq(1)
      expect(comp._component.preinstall_actions.last.pkg_state.first).to eq('install')
      expect(comp._component.preinstall_actions.last.scripts.first).to eq('echo "hello, world"')
    end

    it 'fails with bad preinstall action' do
      comp = Vanagon::Component::DSL.new('action-test', {}, dummy_platform_sysv)
      expect { comp.add_preinstall_action('foo', '/bin/true') }.to raise_error(Vanagon::Error)
    end

    it 'fails with empty preinstall action' do
      comp = Vanagon::Component::DSL.new('action-test', {}, dummy_platform_sysv)
      expect { comp.add_preinstall_action([], '/bin/true') }.to raise_error(Vanagon::Error)
    end

    # trigger spec testing
    it 'adds the correct trigger action to the component' do
      comp = Vanagon::Component::DSL.new('action-test', {}, dummy_platform_sysv)
      comp.add_rpm_install_triggers(['install', 'upgrade'], ['chkconfig --list', '/bin/true'], 'puppet-agent')
      comp.add_rpm_install_triggers('install', 'echo "hello, world"', 'puppet-agent')
      expect(comp._component.install_triggers.count).to eq(2)
      expect(comp._component.install_triggers.first.scripts.count).to eq(2)
      expect(comp._component.install_triggers.first.pkg_state.count).to eq(2)
      expect(comp._component.install_triggers.first.pkg_state.first).to eq('install')
      expect(comp._component.install_triggers.first.pkg_state.last).to eq('upgrade')
      expect(comp._component.install_triggers.first.scripts.first).to eq('chkconfig --list')
      expect(comp._component.install_triggers.first.scripts.last).to eq('/bin/true')
      expect(comp._component.install_triggers.first.pkg).to eq ('puppet-agent')

      expect(comp._component.install_triggers.last.scripts.count).to eq(1)
      expect(comp._component.install_triggers.last.pkg_state.count).to eq(1)
      expect(comp._component.install_triggers.last.pkg_state.first).to eq('install')
      expect(comp._component.install_triggers.last.scripts.first).to eq('echo "hello, world"')
      expect(comp._component.install_triggers.last.pkg).to eq('puppet-agent')
    end

    it 'fails with bad install trigger action' do
      comp = Vanagon::Component::DSL.new('action-test', {}, dummy_platform_sysv)
      expect { comp.add_rpm_install_triggers('foo', '/bin/true', 'puppet-agent') }.to raise_error(Vanagon::Error)
    end

    it 'fails with empty install trigger action' do
      comp = Vanagon::Component::DSL.new('action-test', {}, dummy_platform_sysv)
      expect { comp.add_rpm_install_triggers([], '/bin/true', 'puppet-agent') }.to raise_error(Vanagon::Error)
    end

    it 'adds debian interest triggers' do
      comp = Vanagon::Component::DSL.new('action-test', {}, '')
      comp.add_debian_interest_triggers(['install', 'upgrade'], ['chkconfig --list', '/bin/true'], 'puppet-agent-interest')
      comp.add_debian_interest_triggers('install', 'echo "hello, world"', 'puppet-agent-interest')
      expect(comp._component.interest_triggers.count).to eq(2)
      expect(comp._component.interest_triggers.first.scripts.count).to eq(2)
      expect(comp._component.interest_triggers.first.pkg_state.count).to eq(2)
      expect(comp._component.interest_triggers.first.pkg_state.first).to eq('install')
      expect(comp._component.interest_triggers.first.pkg_state.last).to eq('upgrade')
      expect(comp._component.interest_triggers.first.scripts.first).to eq('chkconfig --list')
      expect(comp._component.interest_triggers.first.scripts.last).to eq('/bin/true')
      expect(comp._component.interest_triggers.first.interest_name).to eq ('puppet-agent-interest')

      expect(comp._component.interest_triggers.last.scripts.count).to eq(1)
      expect(comp._component.interest_triggers.last.pkg_state.count).to eq(1)
      expect(comp._component.interest_triggers.last.pkg_state.first).to eq('install')
      expect(comp._component.interest_triggers.last.scripts.first).to eq('echo "hello, world"')
      expect(comp._component.interest_triggers.last.interest_name).to eq('puppet-agent-interest')
    end

    it 'adds debian activate triggers' do
      comp = Vanagon::Component::DSL.new('action-test', {}, '')
      comp.add_debian_activate_triggers('puppet-agent-activate')
      expect(comp._component.activate_triggers.count).to eq(1)
      expect(comp._component.activate_triggers.first.activate_name).to eq ('puppet-agent-activate')
    end

    it 'adds the corect postinstall action to the component' do
      comp = Vanagon::Component::DSL.new('action-test', {}, dummy_platform_sysv)
      comp.add_postinstall_action(['install', 'upgrade'], ['chkconfig --list', '/bin/true'])
      comp.add_postinstall_action('install', 'echo "hello, world"')
      expect(comp._component.postinstall_actions.count).to eq(2)
      expect(comp._component.postinstall_actions.first.scripts.count).to eq(2)
      expect(comp._component.postinstall_actions.first.pkg_state.count).to eq(2)
      expect(comp._component.postinstall_actions.first.pkg_state.first).to eq('install')
      expect(comp._component.postinstall_actions.first.pkg_state.last).to eq('upgrade')
      expect(comp._component.postinstall_actions.first.scripts.first).to eq('chkconfig --list')
      expect(comp._component.postinstall_actions.first.scripts.last).to eq('/bin/true')

      expect(comp._component.postinstall_actions.last.scripts.count).to eq(1)
      expect(comp._component.postinstall_actions.last.pkg_state.count).to eq(1)
      expect(comp._component.postinstall_actions.last.pkg_state.first).to eq('install')
      expect(comp._component.postinstall_actions.last.scripts.first).to eq('echo "hello, world"')
    end

    it 'fails with bad postinstall action' do
      comp = Vanagon::Component::DSL.new('action-test', {}, dummy_platform_sysv)
      expect { comp.add_postinstall_action('foo', '/bin/true') }.to raise_error(Vanagon::Error)
    end

    it 'fails with empty postinstall action' do
      comp = Vanagon::Component::DSL.new('action-test', {}, dummy_platform_sysv)
      expect { comp.add_postinstall_action([], '/bin/true') }.to raise_error(Vanagon::Error)
    end

    it 'adds the correct preremove action to the component' do
      comp = Vanagon::Component::DSL.new('action-test', {}, dummy_platform_sysv)
      comp.add_preremove_action(['removal', 'upgrade'], ['chkconfig --list', '/bin/true'])
      comp.add_preremove_action('removal', 'echo "hello, world"')
      expect(comp._component.preremove_actions.count).to eq(2)
      expect(comp._component.preremove_actions.first.scripts.count).to eq(2)
      expect(comp._component.preremove_actions.first.pkg_state.count).to eq(2)
      expect(comp._component.preremove_actions.first.pkg_state.first).to eq('removal')
      expect(comp._component.preremove_actions.first.pkg_state.last).to eq('upgrade')
      expect(comp._component.preremove_actions.first.scripts.first).to eq('chkconfig --list')
      expect(comp._component.preremove_actions.first.scripts.last).to eq('/bin/true')

      expect(comp._component.preremove_actions.last.scripts.count).to eq(1)
      expect(comp._component.preremove_actions.last.pkg_state.count).to eq(1)
      expect(comp._component.preremove_actions.last.pkg_state.first).to eq('removal')
      expect(comp._component.preremove_actions.last.scripts.first).to eq('echo "hello, world"')
    end

    it 'fails with bad preremove action' do
      comp = Vanagon::Component::DSL.new('action-test', {}, dummy_platform_sysv)
      expect { comp.add_preremove_action('foo', '/bin/true') }.to raise_error(Vanagon::Error)
    end

    it 'fails with empty preremove action' do
      comp = Vanagon::Component::DSL.new('action-test', {}, dummy_platform_sysv)
      expect { comp.add_preremove_action([], '/bin/true') }.to raise_error(Vanagon::Error)
    end

    it 'adds the corect postremove action to the component' do
      comp = Vanagon::Component::DSL.new('action-test', {}, dummy_platform_sysv)
      comp.add_postremove_action(['removal', 'upgrade'], ['chkconfig --list', '/bin/true'])
      comp.add_postremove_action('removal', 'echo "hello, world"')
      expect(comp._component.postremove_actions.count).to eq(2)
      expect(comp._component.postremove_actions.first.scripts.count).to eq(2)
      expect(comp._component.postremove_actions.first.pkg_state.count).to eq(2)
      expect(comp._component.postremove_actions.first.pkg_state.first).to eq('removal')
      expect(comp._component.postremove_actions.first.pkg_state.last).to eq('upgrade')
      expect(comp._component.postremove_actions.first.scripts.first).to eq('chkconfig --list')
      expect(comp._component.postremove_actions.first.scripts.last).to eq('/bin/true')

      expect(comp._component.postremove_actions.last.scripts.count).to eq(1)
      expect(comp._component.postremove_actions.last.pkg_state.count).to eq(1)
      expect(comp._component.postremove_actions.last.pkg_state.first).to eq('removal')
      expect(comp._component.postremove_actions.last.scripts.first).to eq('echo "hello, world"')
    end

    it 'fails with bad postremove action' do
      comp = Vanagon::Component::DSL.new('action-test', {}, dummy_platform_sysv)
      expect { comp.add_postremove_action('foo', '/bin/true') }.to raise_error(Vanagon::Error)
    end

    it 'fails with empty postremove action' do
      comp = Vanagon::Component::DSL.new('action-test', {}, dummy_platform_sysv)
      expect { comp.add_postremove_action([], '/bin/true') }.to raise_error(Vanagon::Error)
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
      expect(comp._component.configfiles).to include(Vanagon::Common::Pathname.configfile('/etc/default/service-test'))
      expect(comp._component.files).to include(Vanagon::Common::Pathname.file('/etc/init.d/service-test', mode: '0755'))

      # The component should now have a service registered
      expect(comp._component.service.name).to eq('service-test')
    end

    it 'reads from a file when the OS is AIX for services' do
      comp = Vanagon::Component::DSL.new('service-test', {}, dummy_platform_aix)
      comp.install_service('spec/fixtures/component/mcollective.service', nil, 'mcollective')
      expect(comp._component.service.name).to eq('mcollective')
      expect(comp._component.service.service_command).to include('/opt/puppetlabs/puppet/bin/ruby')
      expect(comp._component.service.service_command).not_to include("\n")
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
      expect(comp._component.configfiles).to include(Vanagon::Common::Pathname.configfile('/etc/default/service-test'))
      expect(comp._component.files).to include(Vanagon::Common::Pathname.file('/usr/lib/systemd/system/service-test.service', mode: '0644'))

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
      expect(comp._component.configfiles).to include(Vanagon::Common::Pathname.configfile('/lib/svc/method/service-test'))
      expect(comp._component.files).to include(Vanagon::Common::Pathname.file('/var/svc/manifest/network/service-test.xml', mode: '0644'))

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
      expect(comp._component.configfiles).to include(Vanagon::Common::Pathname.configfile('/lib/svc/method/service-test'))
      expect(comp._component.files).to include(Vanagon::Common::Pathname.file('/var/svc/manifest/service-test.xml', mode: '0644'))

      # The component should now have a service registered
      expect(comp._component.service.name).to eq('service-test')
    end

    it 'installs the file as a link when link_target is specified' do
      comp = Vanagon::Component::DSL.new('service-test', {}, dummy_platform_sysv)
      comp.install_service('component-client.init', 'component-client.sysconfig', link_target: '/tmp/service-test')
      # Look for servicedir creation and copy
      expect(comp._component.install).to include("install -d '/etc/init.d'")
      expect(comp._component.install).to include("cp -p 'component-client.init' '/tmp/service-test'")
      expect(comp._component.install).to include("([[ '/etc/init.d/service-test' -ef '/tmp/service-test' ]] || ln -s '/tmp/service-test' '/etc/init.d/service-test')")

      # Look for defaultdir creation and copy
      expect(comp._component.install).to include("install -d '/etc/default'")
      expect(comp._component.install).to include("cp -p 'component-client.sysconfig' '/etc/default/service-test'")

      # Look for files and configfiles
      expect(comp._component.configfiles).to include(Vanagon::Common::Pathname.configfile('/etc/default/service-test'))
      expect(comp._component.files).to include(Vanagon::Common::Pathname.file('/tmp/service-test', mode: '0755'))
      expect(comp._component.files).to include(Vanagon::Common::Pathname.file('/etc/init.d/service-test'))

      # The component should now have a service registered
      expect(comp._component.service.name).to eq('service-test')
    end
  end

  describe '#install_file' do
    it 'installs correctly using GNU install on AIX' do
      comp = Vanagon::Component::DSL.new('install-file-test', {}, dummy_platform_aix)
      comp.install_file('thing1', 'place/to/put/thing1')
      expect(comp._component.install).to include("/opt/freeware/bin/install -d 'place/to/put'")
      expect(comp._component.install).to include("cp -p 'thing1' 'place/to/put/thing1'")
    end

    it 'adds the correct commands to the install to copy the file' do
      comp = Vanagon::Component::DSL.new('install-file-test', {}, platform)
      comp.install_file('thing1', 'place/to/put/thing1')
      expect(comp._component.install).to include("install -d 'place/to/put'")
      expect(comp._component.install).to include("cp -p 'thing1' 'place/to/put/thing1'")
    end

    it 'adds an owner and group to the installation' do
      comp = Vanagon::Component::DSL.new('install-file-test', {}, platform)
      comp.install_file('thing1', 'place/to/put/thing1', owner: 'bob', group: 'timmy', mode: '0022')
      expect(comp._component.install).to include("install -d 'place/to/put'")
      expect(comp._component.install).to include("cp -p 'thing1' 'place/to/put/thing1'")
      expect(comp._component.install).to include("chmod 0022 'place/to/put/thing1'")
      expect(comp._component.files).to include(Vanagon::Common::Pathname.file('place/to/put/thing1', mode: '0022', owner: 'bob', group: 'timmy'))
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
          expect(comp._component.configfiles).to include(Vanagon::Common::Pathname.configfile('/place/to/put/thing1'))
          expect(comp._component.configfiles).not_to include(Vanagon::Common::Pathname.file('/place/to/put/thing1'))
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
          expect(comp._component.configfiles).to include(Vanagon::Common::Pathname.configfile('place/to/put/thing1', mode: '0644'))
          expect(comp._component.files).not_to include(Vanagon::Common::Pathname.file('place/to/put/thing1'))
        end

        it 'sets owner, group, and mode for the configfiles' do
          comp = Vanagon::Component::DSL.new('install-config-file-test', {}, platform)
          comp.install_configfile('thing1', 'place/to/put/thing1', owner: 'bob', group: 'timmy', mode: '0022')
          expect(comp._component.configfiles).to include(Vanagon::Common::Pathname.configfile('place/to/put/thing1', mode: '0022', group: 'timmy', owner: 'bob'))
          expect(comp._component.files).not_to include(Vanagon::Common::Pathname.file('place/to/put/thing1'))
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
          expect(comp._component.configfiles).to include(Vanagon::Common::Pathname.configfile('/place/to/put/thing1.pristine'))
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
          expect(comp._component.configfiles).to include(Vanagon::Common::Pathname.configfile('place/to/put/thing1.pristine', mode: '0644'))
          expect(comp._component.configfiles).not_to include(Vanagon::Common::Pathname.file('place/to/put/thing1'))
        end
      end
    end
  end

  describe "#build_dir" do
    it "sets the build_dir when given a relative path" do
      comp = Vanagon::Component::DSL.new('build-dir-test', {}, platform)
      comp.build_dir("build")
      expect(comp._component.build_dir).to eq("build")
    end

    it "raises an error when given an absolute path" do
      comp = Vanagon::Component::DSL.new('build-dir-test', {}, platform)
      expect {
        comp.build_dir("/build")
      }.to raise_error(Vanagon::Error, %r[build_dir should be a relative path, but '/build' looks to be absolute\.])
    end
  end

  describe '#link' do
    it 'adds the correct command to the install for the component' do
      comp = Vanagon::Component::DSL.new('link-test', {}, platform)
      comp.link('link-source', '/place/to/put/things')
      expect(comp._component.install).to include("install -d '/place/to/put'")
      expect(comp._component.install).to include("([[ '/place/to/put/things' -ef 'link-source' ]] || ln -s 'link-source' '/place/to/put/things')")
    end
  end

  describe '#environment' do
    before :each do
      @comp = Vanagon::Component::DSL.new('env-test', {}, {})
    end

    before :example do
      @path = {'PATH' => '/usr/local/bin'}
      @alternate_path = {'PATH' => '/usr/bin'}
      @cflags = {'CFLAGS' => '-I /usr/local/bin'}
      @merged_env = @cflags.merge(@alternate_path)
    end

    it 'adds an override to the environment for a component' do
      @comp.environment(@path)
      @path.each_pair do |key, value|
        expect(@comp._component.environment[key]).to eq(value)
      end
    end

    it 'merges against the existing environment' do
      # Set a value that should *NOT* be present
      @comp.environment(@path)
      # And then set two values that should
      @comp.environment(@alternate_path)
      @comp.environment(@cflags)

      # Test that our canary doesn't exist
      @path.each_pair do |key, value|
        expect(@comp._component.environment[key]).to_not eq(value)
      end

      # And then validate our expected values
      @merged_env.each_pair do |key, value|
        expect(@comp._component.environment[key]).to eq(value)
      end
    end
  end

  describe '#directory' do
    it 'adds a directory with the desired path to the directory collection for the component' do
      comp = Vanagon::Component::DSL.new('directory-test', {}, platform)
      comp.directory('/a/b/c')
      expect(comp._component.directories).to include(Vanagon::Common::Pathname.new('/a/b/c'))
    end

    it 'adds a directory with the desired mode to the directory collection for the component' do
      comp = Vanagon::Component::DSL.new('directory-test', {}, platform)
      comp.directory('/a/b/c', mode: '0755')
      expect(comp._component.install).to include("install -d -m '0755' '/a/b/c'")
      expect(comp._component.directories.first).to eq(Vanagon::Common::Pathname.new('/a/b/c', mode: '0755'))
    end

    it 'adds a directory with the desired owner to the directory collection for the component' do
      comp = Vanagon::Component::DSL.new('directory-test', {}, platform)
      comp.directory('/a/b/c', owner: 'olivia')
      expect(comp._component.install).to include("install -d '/a/b/c'")
      expect(comp._component.directories.first).to eq(Vanagon::Common::Pathname.new('/a/b/c', owner: 'olivia'))
    end

    it 'adds a directory with the desired group to the directory collection for the component' do
      comp = Vanagon::Component::DSL.new('directory-test', {}, platform)
      comp.directory('/a/b/c', group: 'release-engineering')
      expect(comp._component.install).to include("install -d '/a/b/c'")
      expect(comp._component.directories.first).to eq(Vanagon::Common::Pathname.new('/a/b/c', group: 'release-engineering'))
    end

    it 'adds a directory with the desired attributes to the directory collection for the component' do
      comp = Vanagon::Component::DSL.new('directory-test', {}, platform)
      comp.directory('/a/b/c', mode: '0400', owner: 'olivia', group: 'release-engineering')
      expect(comp._component.install).to include("install -d -m '0400' '/a/b/c'")
      expect(comp._component.directories.first).to eq(Vanagon::Common::Pathname.new('/a/b/c', mode: '0400', owner: 'olivia', group: 'release-engineering'))
    end
  end
end
