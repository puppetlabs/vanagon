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
end
