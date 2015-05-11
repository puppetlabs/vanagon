require 'vanagon/platform/dsl'

describe 'Vanagon::Platform::DSL' do
  let (:deb_platform_block)  {  "platform 'debian-test-fixture' do |plat| end" }
  let (:el_5_platform_block)   {  "platform 'el-5-fixture'     do |plat| end" }
  let (:el_6_platform_block)   {  "platform 'el-6-fixture'     do |plat| end" }
  let (:sles_platform_block) {  "platform 'sles-test-fixture'   do |plat| end" }

  let(:apt_definition) { "http://builds.puppetlabs.lan/puppet-agent/0.2.1/repo_configs/deb/pl-puppet-agent-0.2.1-wheezy" }
  let(:apt_definition_deb) { "http://builds.puppetlabs.lan/puppet-agent/0.2.1/repo_configs/deb/pl-puppet-agent-0.2.1-wheezy.deb" }
  let(:apt_definition_gpg) { "http://pl-build-tools.delivery.puppetlabs.net/debian/keyring.gpg" }
  let(:el_definition) { "http://builds.puppetlabs.lan/puppet-agent/0.2.1/repo_configs/rpm/pl-puppet-agent-0.2.1-el-7-x86_64" }
  let(:el_definition_rpm) { "http://builds.puppetlabs.lan/puppet-agent/0.2.1/repo_configs/rpm/pl-puppet-agent-0.2.1-release.rpm" }
  let(:sles_definition) { "http://builds.puppetlabs.lan/puppet-agent/0.2.2/repo_configs/rpm/pl-puppet-agent-0.2.2-sles-12-x86_64" }
  let(:sles_definition_rpm) { "http://builds.puppetlabs.lan/puppet-agent/0.2.1/repo_configs/rpm/pl-puppet-agent-0.2.1-release.rpm" }

  describe '#apt_repo' do
    it "grabs the file and adds .list to it" do
      plat = Vanagon::Platform::DSL.new('debian-test-fixture')
      expect(SecureRandom).to receive(:hex).and_return("906264d248061b0edb1a576cc9c8f6c7")
      plat.instance_eval(deb_platform_block)
      plat.apt_repo(apt_definition)
      expect(plat._platform.provisioning).to include("curl -o '/etc/apt/sources.list.d/906264d248061b0edb1a576cc9c8f6c7-pl-puppet-agent-0.2.1-wheezy.list' '#{apt_definition}'")
    end

    it "installs a deb when given a deb" do
      plat = Vanagon::Platform::DSL.new('debian-test-fixture')
      plat.instance_eval(deb_platform_block)
      plat.apt_repo(apt_definition_deb)
      expect(plat._platform.provisioning).to include("curl -o local.deb '#{apt_definition_deb}'; dpkg -i local.deb; rm -f local.deb")
    end

    it "installs a gpg key if given one" do
      plat = Vanagon::Platform::DSL.new('debian-test-fixture')
      expect(SecureRandom).to receive(:hex).and_return("906264d248061b0edb1a576cc9c8f6c7").twice
      plat.instance_eval(deb_platform_block)
      plat.apt_repo(apt_definition, apt_definition_gpg)
      expect(plat._platform.provisioning).to include("curl -o '/etc/apt/trusted.gpg.d/906264d248061b0edb1a576cc9c8f6c7-keyring.gpg' '#{apt_definition_gpg}'")
    end
  end

  describe '#yum_repo' do
    it "grabs the file and adds .repo to it" do
      plat = Vanagon::Platform::DSL.new('el-5-fixture')
      expect(SecureRandom).to receive(:hex).and_return("906264d248061b0edb1a576cc9c8f6c7")
      plat.instance_eval(el_5_platform_block)
      plat.yum_repo(el_definition)
      expect(plat._platform.provisioning).to include("curl -o '/etc/yum.repos.d/906264d248061b0edb1a576cc9c8f6c7-pl-puppet-agent-0.2.1-el-7-x86_64.repo' '#{el_definition}'")
    end

    describe "installs a rpm when given a rpm" do
      it 'uses yum on el 6 and higher' do
        plat = Vanagon::Platform::DSL.new('el-6-fixture')
        plat.instance_eval(el_6_platform_block)
        plat.yum_repo(el_definition_rpm)
        expect(plat._platform.provisioning).to include("yum localinstall -y '#{el_definition_rpm}'")
      end

      it 'uses rpm on el 5 and lower' do
        plat = Vanagon::Platform::DSL.new('el-5-fixture')
        plat.instance_eval(el_5_platform_block)
        plat.yum_repo(el_definition_rpm)
        expect(plat._platform.provisioning).to include("curl -o local.rpm '#{el_definition_rpm}'; rpm -Uvh local.rpm; rm -f local.rpm")
      end
    end
  end

  describe '#zypper_repo' do
    it "grabs the file and adds .repo to it" do
      plat = Vanagon::Platform::DSL.new('sles-test-fixture')
      plat.instance_eval(sles_platform_block)
      plat.zypper_repo(sles_definition)
      expect(plat._platform.provisioning).to be_include("yes | zypper -n --no-gpg-checks ar -t YUM --repo '#{sles_definition}'")
    end

    it "installs a sles rpm when given a rpm" do
      plat = Vanagon::Platform::DSL.new('sles-test-fixture')
      plat.instance_eval(sles_platform_block)
      plat.zypper_repo(sles_definition_rpm)
      expect(plat._platform.provisioning).to be_include("curl -o local.rpm '#{sles_definition_rpm}'; rpm -Uvh local.rpm; rm -f local.rpm")
    end
  end
end
