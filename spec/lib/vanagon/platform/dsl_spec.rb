require 'vanagon/platform/dsl'

describe 'Vanagon::Platform::DSL' do
  let (:deb_platform_block)  {  "platform 'debian-test-fixture' do |plat| end" }
  let (:el_platform_block)   {  "platform 'el-test-fixture'     do |plat| end" }
  let (:sles_platform_block) {  "platform 'sles-test-fixture'   do |plat| end" }

  let(:apt_definition) { "http://builds.puppetlabs.lan/puppet-agent/0.2.1/repo_configs/deb/pl-puppet-agent-0.2.1-wheezy" }
  let(:apt_definition_deb) { "http://builds.puppetlabs.lan/puppet-agent/0.2.1/repo_configs/deb/pl-puppet-agent-0.2.1-wheezy.deb" }
  let(:el_definition) { "http://builds.puppetlabs.lan/puppet-agent/0.2.1/repo_configs/rpm/pl-puppet-agent-0.2.1-el-7-x86_64" }
  let(:el_definition_rpm) { "http://builds.puppetlabs.lan/puppet-agent/0.2.1/repo_configs/rpm/pl-puppet-agent-0.2.1-release.rpm" }
  let(:sles_definition) { "http://builds.puppetlabs.lan/puppet-agent/0.2.2/repo_configs/rpm/pl-puppet-agent-0.2.2-sles-12-x86_64" }
  let(:sles_definition_rpm) { "http://builds.puppetlabs.lan/puppet-agent/0.2.1/repo_configs/rpm/pl-puppet-agent-0.2.1-release.rpm" }

  describe '#apt_repo' do
    it "grabs the file and adds .list to it" do
      plat = Vanagon::Platform::DSL.new('debian-test-fixture')
      plat.instance_eval(deb_platform_block)
      expect(Digest::MD5).to receive(:hexdigest).with(apt_definition).and_return("abcdefghij")
      plat.apt_repo(apt_definition)
      expect(plat._platform.provisioning).to include("curl -o '/etc/apt/sources.list.d/somerepo-abcdefg.list' '#{apt_definition}'; apt-get -qq update")
    end

    it "installs a deb when given a deb" do
      plat = Vanagon::Platform::DSL.new('debian-test-fixture')
      plat.instance_eval(deb_platform_block)
      expect(Digest::MD5).to receive(:hexdigest).with(apt_definition_deb).and_return("abcdefghij")
      plat.apt_repo(apt_definition_deb)
      expect(plat._platform.provisioning).to include("curl -o local.deb '#{apt_definition_deb}'; dpkg -i local.deb; rm -f local.deb")
    end
  end

  describe '#yum_repo' do
    it "grabs the file and adds .repo to it" do
      plat = Vanagon::Platform::DSL.new('el-test-fixture')
      plat.instance_eval(el_platform_block)
      expect(Digest::MD5).to receive(:hexdigest).with(el_definition).and_return("abcdefghij")
      plat.yum_repo(el_definition)
      expect(plat._platform.provisioning).to include("curl -o '/etc/yum.repos.d/somerepo-abcdefg.repo' '#{el_definition}'")
    end

    it "installs a rpm when given a rpm" do
      plat = Vanagon::Platform::DSL.new('el-test-fixture')
      plat.instance_eval(el_platform_block)
      expect(Digest::MD5).to receive(:hexdigest).with(el_definition_rpm).and_return("abcdefghij")
      plat.yum_repo(el_definition_rpm)
      expect(plat._platform.provisioning).to include("yum localinstall -y '#{el_definition_rpm}'")
    end
  end

  describe '#zypper_repo' do
    it "grabs the file and adds .repo to it" do
      plat = Vanagon::Platform::DSL.new('sles-test-fixture')
      plat.instance_eval(sles_platform_block)
      expect(Digest::MD5).to receive(:hexdigest).with(sles_definition).and_return("abcdefghij")
      plat.zypper_repo(sles_definition)
      expect(plat._platform.provisioning).to be_include("yes | zypper -n --no-gpg-checks ar -t YUM --repo '#{sles_definition}'")
    end

    it "installs a sles rpm when given a rpm" do
      plat = Vanagon::Platform::DSL.new('sles-test-fixture')
      plat.instance_eval(sles_platform_block)
      expect(Digest::MD5).to receive(:hexdigest).with(sles_definition_rpm).and_return("abcdefghij")
      plat.zypper_repo(sles_definition_rpm)
      expect(plat._platform.provisioning).to be_include("curl -o local.rpm '#{sles_definition_rpm}'; rpm -Uvh local.rpm; rm -f local.rpm")
    end
  end
end
