require 'vanagon/component'

describe "Vanagon::Component" do
  describe "#get_environment" do
    it "returns a makefile compatible environment" do
      comp = Vanagon::Component.new('env-test', {}, {})
      comp.environment = {'PATH' => '/usr/local/bin'}
      expect(comp.get_environment).to eq('export PATH="/usr/local/bin"')
    end

    it 'merges against the existing environment' do
      comp = Vanagon::Component.new('env-test', {}, {})
      comp.environment = {'PATH' => '/usr/bin', 'CFLAGS' => '-I /usr/local/bin'}
      expect(comp.get_environment).to eq('export PATH="/usr/bin" CFLAGS="-I /usr/local/bin"')
    end

    it 'returns : for an empty environment' do
      comp = Vanagon::Component.new('env-test', {}, {})
      expect(comp.get_environment).to eq(':')
    end
  end
end
