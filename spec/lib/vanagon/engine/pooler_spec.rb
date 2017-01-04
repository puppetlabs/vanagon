require 'vanagon/engine/pooler'
require 'vanagon/platform'

describe 'Vanagon::Engine::Pooler' do
  let (:platform) { double(Vanagon::Platform, :target_user => 'root') }
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

  before :each do
    # suppress `#warn` output during tests
    allow_any_instance_of(Vanagon::Platform::DSL).to receive(:warn)
  end

  describe "#load_token" do
    after(:each) { ENV['VMPOOLER_TOKEN'] = nil }

    let(:token_file) { double(File) }
    let(:token_filename) { 'decade' }

    it 'prefers an environment variable to a file' do
      ENV['VMPOOLER_TOKEN'] = 'cafebeef'
      expect_any_instance_of(Vanagon::Engine::Pooler).to_not receive(:token_from_file)
      expect(Vanagon::Engine::Pooler.new(platform).token).to_not eq('decade')
      expect(Vanagon::Engine::Pooler.new(platform).token).to eq('cafebeef')
    end

    it 'falls back to a file if the environment variable is not set' do
      allow_any_instance_of(Vanagon::Engine::Pooler).to receive(:token_from_file).and_return('decade')
      expect(Vanagon::Engine::Pooler.new(platform).token).to eq('decade')
    end

    it 'returns nil if there is no env var or file' do
      allow_any_instance_of(Vanagon::Engine::Pooler).to receive(:token_from_file).and_return(nil)
      expect(Vanagon::Engine::Pooler.new(platform).token).to be_nil
    end
  end

  describe "#validate_platform" do
    it 'raises an error if the platform is missing a required attribute' do
      expect{ Vanagon::Engine::Pooler.new(platform_without_vcloud_name).validate_platform }.to raise_error(Vanagon::Error)
    end

    it 'returns true if the platform has the required attributes' do
      expect(Vanagon::Engine::Pooler.new(platform_with_vcloud_name).validate_platform).to be(true)
    end
  end

  it 'returns "pooler" name' do
    expect(Vanagon::Engine::Pooler.new(platform_with_vcloud_name).name).to eq('pooler')
  end
end
