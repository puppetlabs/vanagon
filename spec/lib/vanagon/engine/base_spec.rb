require 'vanagon/engine/base'

describe 'Vanagon::Engine::Base' do
  let (:platform_without_ssh_port) {
    plat = Vanagon::Platform::DSL.new('debian-6-i386')
    plat.instance_eval("platform 'debian-6-i386' do |plat|
                      plat.ssh_port nil
                    end")
    plat._platform
  }

  let (:platform) {
    plat = Vanagon::Platform::DSL.new('debian-6-i386')
    plat.instance_eval("platform 'debian-6-i386' do |plat|
                    end")
    plat._platform
  }

  describe '#select_target' do
    it 'raises an error without a target' do
      base = Vanagon::Engine::Base.new(platform)
      expect { base.select_target }.to raise_error(Vanagon::Error)
    end

    it 'returns a target if one is set' do
      base = Vanagon::Engine::Base.new(platform, 'abcd')
      expect(base.select_target).to eq('abcd')
    end
  end

  describe '#validate_platform' do
    it 'raises an error if the platform is missing a required attribute' do
      expect{ Vanagon::Engine::Base.new(platform_without_ssh_port).validate_platform }.to raise_error(Vanagon::Error)
    end

    it 'returns true if the platform has the required attributes' do
      expect(Vanagon::Engine::Base.new(platform).validate_platform).to be(true)
    end
  end

  describe "#retrieve_built_artifact" do
    it 'creates a new output dir' do
      base = Vanagon::Engine::Base.new(platform)
      allow(Vanagon::Utilities).to receive(:rsync_from)
      expect(FileUtils).to receive(:mkdir_p)
      base.retrieve_built_artifact([], false)
    end

    it 'rsync uses normal output dir when no_package param is false' do
      base = Vanagon::Engine::Base.new(platform, 'abcd')
      allow(FileUtils).to receive(:mkdir_p)
      expect(Vanagon::Utilities).to receive(:rsync_from).with('/output/*', 'root@abcd', 'output/', 22)
      base.retrieve_built_artifact([], false)
    end

    it 'rsync only contents of parameter if no_package is true' do
      base = Vanagon::Engine::Base.new(platform, 'abcd')
      allow(FileUtils).to receive(:mkdir_p)
      expect(Vanagon::Utilities).to receive(:rsync_from).with('foo/bar/baz.file', 'root@abcd', 'output/', 22)
      base.retrieve_built_artifact(['foo/bar/baz.file'], true)
    end

    it 'rsync only contents of parameter with multiple entries if no_package param is true' do
      base = Vanagon::Engine::Base.new(platform, 'abcd')
      allow(FileUtils).to receive(:mkdir_p)
      expect(Vanagon::Utilities).to receive(:rsync_from).with('foo/bar/baz.file', 'root@abcd', 'output/', 22)
      expect(Vanagon::Utilities).to receive(:rsync_from).with('foo/foobar/foobarbaz.file', 'root@abcd', 'output/', 22)
      base.retrieve_built_artifact(['foo/bar/baz.file', 'foo/foobar/foobarbaz.file'], true)
    end
  end
end
