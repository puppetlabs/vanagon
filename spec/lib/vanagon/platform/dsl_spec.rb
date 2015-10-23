require 'vanagon/platform/dsl'

describe 'Vanagon::Platform::DSL' do
  let (:deb_platform_block)    { "platform 'debian-test-fixture' do |plat| end" }
  let (:el_5_platform_block)   { "platform 'el-5-fixture'        do |plat| end" }
  let (:el_6_platform_block)   { "platform 'el-6-fixture'        do |plat| end" }
  let (:sles_platform_block)   { "platform 'sles-test-fixture'   do |plat| end" }
  let (:cicso_wrlinux_platform_block) { "platform 'cisco-wrlinux-fixture'      do |plat| end" }
  let (:solaris_10_platform_block) { "platform 'solaris-10-fixture'      do |plat| end" }
  let (:solaris_11_platform_block) { "platform 'solaris-11-fixture'      do |plat| end" }

  let(:apt_definition) { "http://builds.delivery.puppetlabs.net/puppet-agent/0.2.1/repo_configs/deb/pl-puppet-agent-0.2.1-wheezy" }
  let(:apt_definition_deb) { "http://builds.delivery.puppetlabs.net/puppet-agent/0.2.1/repo_configs/deb/pl-puppet-agent-0.2.1-wheezy.deb" }
  let(:apt_definition_gpg) { "http://pl-build-tools.delivery.puppetlabs.net/debian/keyring.gpg" }
  let(:el_definition) { "http://builds.delivery.puppetlabs.net/puppet-agent/0.2.1/repo_configs/rpm/pl-puppet-agent-0.2.1-el-7-x86_64" }
  let(:el_definition_rpm) { "http://builds.delivery.puppetlabs.net/puppet-agent/0.2.1/repo_configs/rpm/pl-puppet-agent-0.2.1-release.rpm" }
  let(:sles_definition) { "http://builds.delivery.puppetlabs.net/puppet-agent/0.2.2/repo_configs/rpm/pl-puppet-agent-0.2.2-sles-12-x86_64" }
  let(:sles_definition_rpm) { "http://builds.delivery.puppetlabs.net/puppet-agent/0.2.1/repo_configs/rpm/pl-puppet-agent-0.2.1-release-sles.rpm" }
  let(:cisco_wrlinux_definition) { "http://builds.delivery.puppetlabs.net/puppet-agent/0.2.1/repo_configs/rpm/pl-puppet-agent-0.2.1-cisco-wrlinux-5-x86_64.repo" }

  let(:hex_value) { "906264d248061b0edb1a576cc9c8f6c7" }

  # These apt_repo, yum_repo, and zypper_repo methods are all deprecated.
  describe '#apt_repo' do
    it "grabs the file and adds .list to it" do
      plat = Vanagon::Platform::DSL.new('debian-test-fixture')
      expect(SecureRandom).to receive(:hex).and_return(hex_value)
      plat.instance_eval(deb_platform_block)
      plat.apt_repo(apt_definition)
      expect(plat._platform.provisioning).to include("curl -o '/etc/apt/sources.list.d/#{hex_value}-pl-puppet-agent-0.2.1-wheezy.list' '#{apt_definition}'")
    end

    it "installs a deb when given a deb" do
      plat = Vanagon::Platform::DSL.new('debian-test-fixture')
      plat.instance_eval(deb_platform_block)
      plat.apt_repo(apt_definition_deb)
      expect(plat._platform.provisioning).to include("curl -o local.deb '#{apt_definition_deb}' && dpkg -i local.deb; rm -f local.deb")
    end

    it "installs a gpg key if given one" do
      plat = Vanagon::Platform::DSL.new('debian-test-fixture')
      expect(SecureRandom).to receive(:hex).and_return(hex_value).twice
      plat.instance_eval(deb_platform_block)
      plat.apt_repo(apt_definition, apt_definition_gpg)
      expect(plat._platform.provisioning).to include("curl -o '/etc/apt/trusted.gpg.d/#{hex_value}-keyring.gpg' '#{apt_definition_gpg}'")
    end
  end

  describe '#yum_repo' do
    it "grabs the file and adds .repo to it" do
      plat = Vanagon::Platform::DSL.new('el-5-fixture')
      expect(SecureRandom).to receive(:hex).and_return(hex_value)
      plat.instance_eval(el_5_platform_block)
      plat.yum_repo(el_definition)
      expect(plat._platform.provisioning).to include("curl -o '/etc/yum.repos.d/#{hex_value}-pl-puppet-agent-0.2.1-el-7-x86_64.repo' '#{el_definition}'")
    end

    # This test currently covers wrlinux 5 and 7
    it "downloads the repo file to the correct yum location for wrlinux" do
      plat = Vanagon::Platform::DSL.new('cisco-wrlinux-fixture')
      expect(SecureRandom).to receive(:hex).and_return(hex_value)
      plat.instance_eval(cicso_wrlinux_platform_block)
      plat.yum_repo(cisco_wrlinux_definition)
      expect(plat._platform.provisioning).to include("curl -o '/etc/yum/repos.d/#{hex_value}-pl-puppet-agent-0.2.1-cisco-wrlinux-5-x86_64.repo' '#{cisco_wrlinux_definition}'")
    end

    describe "installs a rpm when given a rpm" do
      it 'uses rpm everywhere' do
        plat = Vanagon::Platform::DSL.new('el-5-fixture')
        plat.instance_eval(el_5_platform_block)
        plat.yum_repo(el_definition_rpm)
        expect(plat._platform.provisioning).to include("rpm -q curl > /dev/null || yum -y install curl")
        expect(plat._platform.provisioning).to include("curl -o local.rpm '#{el_definition_rpm}'; rpm -Uvh local.rpm; rm -f local.rpm")
      end
    end
  end

  describe '#zypper_repo' do
    it "grabs the file and adds .repo to it" do
      plat = Vanagon::Platform::DSL.new('sles-test-fixture')
      plat.instance_eval(sles_platform_block)
      plat.zypper_repo(sles_definition)
      expect(plat._platform.provisioning).to include("yes | zypper -n --no-gpg-checks ar -t YUM --repo '#{sles_definition}'")
    end

    it "installs a sles rpm when given a rpm" do
      plat = Vanagon::Platform::DSL.new('sles-test-fixture')
      plat.instance_eval(sles_platform_block)
      plat.zypper_repo(sles_definition_rpm)
      expect(plat._platform.provisioning).to include("curl -o local.rpm '#{sles_definition_rpm}'; rpm -Uvh local.rpm; rm -f local.rpm")
    end
  end

  describe '#add_build_repository' do
    it 'hands off to the platform specific method if defined' do
      plat = Vanagon::Platform::DSL.new('solaris-test-fixture')
      plat.instance_eval(solaris_11_platform_block)
      plat.add_build_repository("http://solaris-repo.puppetlabs.com", "puppetlabs.com")
      expect(plat._platform.provisioning).to include("pkg set-publisher -G '*' -g http://solaris-repo.puppetlabs.com puppetlabs.com")
    end

    it 'raises an error if the platform does not define "add_repository"' do
      plat = Vanagon::Platform::DSL.new('solaris-test-fixture')
      plat.instance_eval(solaris_10_platform_block)
      expect {plat.add_build_repository("anything")}.to raise_error(Vanagon::Error, /Adding a build repository not defined/)
    end
  end

  describe '#vmpooler_template' do
    it 'sets the instance variable on platform' do
      plat = Vanagon::Platform::DSL.new('solaris-test-fixture')
      plat.instance_eval(solaris_10_platform_block)
      plat.vmpooler_template 'solaris-10-x86_64'
      expect(plat._platform.vmpooler_template).to eq('solaris-10-x86_64')
    end

    it 'is called by vcloud_name as a deprecation' do
      plat = Vanagon::Platform::DSL.new('solaris-test-fixture')
      plat.instance_eval(solaris_10_platform_block)
      plat.vcloud_name 'solaris-11-x86_64'
      expect(plat._platform.vmpooler_template).to eq('solaris-11-x86_64')
    end
  end
end
