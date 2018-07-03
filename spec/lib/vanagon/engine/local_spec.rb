require 'vanagon/engine/local'
require 'vanagon/platform'

describe 'Vanagon::Engine::Local' do
  let (:platform) {
    plat = Vanagon::Platform::DSL.new('debian-6-i386')
    plat.instance_eval("platform('debian-6-i386') {  }")
    plat._platform
  }

  describe '#validate_platform' do
    it 'succeeds' do
      expect(Vanagon::Engine::Local.new(platform).validate_platform).to be(true)
    end
  end

  describe '#dispatch' do
    it 'execs successfully' do
      engine = Vanagon::Engine::Local.new(platform)
      expect(engine.dispatch('true')).to be(true)
    end

    it 'returns the result if return_output is true' do
      engine = Vanagon::Engine::Local.new(platform)
      expect(engine.dispatch('true', true)).to eq('')
    end
  end

  describe '#retrieve_built_artifacts' do
    it 'copies everything if we package' do
      engine = Vanagon::Engine::Local.new(platform)
      expect(FileUtils).to receive(:mkdir_p).with('output/').and_return true
      expect(Dir).to receive(:glob).with('/output/*').and_return(['tmp/foo', 'tmp/bar'])
      expect(FileUtils).to receive(:cp_r).with(['tmp/foo', 'tmp/bar'], 'output/')
      engine.retrieve_built_artifact([], false)
    end

    it "only copies what you tell it to if we don't package" do
      engine = Vanagon::Engine::Local.new(platform)
      expect(FileUtils).to receive(:mkdir_p).with('output/').and_return true
      expect(Dir).to receive(:glob).with('tmp/bar').and_return(['tmp/bar'])
      expect(FileUtils).to receive(:cp_r).with(['tmp/bar'], 'output/')
      engine.retrieve_built_artifact(['tmp/bar'], true)
    end
  end

  it 'returns "local" name' do
    expect(Vanagon::Engine::Local.new(platform).name).to eq('local')
  end
end
