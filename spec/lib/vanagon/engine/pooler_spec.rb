require 'vanagon/engine/pooler'

describe 'Vanagon::Engine::Pooler' do
  let (:platform_with_vcloud_name) {
    plat = Vanagon::Platform::DSL.new('debian-6-i386')
    plat.instance_eval("platform 'debian-6-i386' do |plat|
                      plat.vcloud_name 'debian-6-i386'
                    end")
    plat._platform
  }

  let (:platform_without_vcloud_name) {
    plat = Vanagon::Platform::DSL.new('debian-6-i386')
    plat.instance_eval("platform 'debian-6-i386' do |plat|
                    end")
    plat._platform
  }

  describe "#validate_platform" do
    it 'raises an error if the platform is missing a required attribute' do
      expect{ Vanagon::Engine::Pooler.new(platform_without_vcloud_name).validate_platform }.to raise_error(Vanagon::Error)
    end

    it 'returns true if the platform has the required attributes' do
      expect(Vanagon::Engine::Pooler.new(platform_with_vcloud_name).validate_platform).to be(true)
    end
  end
end
