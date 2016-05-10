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

  it 'returns "local" name' do
    expect(Vanagon::Engine::Local.new(platform).name).to eq('local')
  end
end
