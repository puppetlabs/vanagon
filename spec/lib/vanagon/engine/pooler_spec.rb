require 'vanagon/engine/pooler'

describe 'Vanagon::Engine::Pooler' do
  let (:platform) { double(Vanagon::Platform) }
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

  describe "#load_token" do
    after(:each) { ENV['VMPOOLER_TOKEN'] = nil }
    after(:each) { ENV['VMPOOL_TOKEN'] = nil }

    let(:token_file) { double(File) }
    let(:token_filename) { 'abcd' }

    it 'prefers an env var to a file' do
      ENV['VMPOOLER_TOKEN'] = 'abcd'
      expect(File).to_not receive(:expand_path).with('~/.vanagon-token')
      expect(Vanagon::Engine::Pooler.new(platform).token).to eq('abcd')
    end

    it 'prefers an alternative env var to a file' do
      ENV['VMPOOL_TOKEN'] = 'abcd'
      expect(File).to_not receive(:expand_path).with('~/.vanagon-token')
      expect(Vanagon::Engine::Pooler.new(platform).token).to eq('abcd')
    end

    it 'falls back to a file if the env var is not set' do
      expect(File).to receive(:expand_path).with('~/.vanagon-token').and_return(token_filename)
      expect(File).to receive(:exist?).with(token_filename).and_return(true)
      expect(File).to receive(:open).with(token_filename).and_return(token_file)
      expect(token_file).to receive(:read).and_return('abcd')
      expect(Vanagon::Engine::Pooler.new(platform).token).to eq('abcd')
    end

    it 'returns nil if there is no env var or file' do
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
end
