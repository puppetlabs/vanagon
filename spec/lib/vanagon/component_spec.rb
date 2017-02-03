require 'vanagon/component'

describe "Vanagon::Component" do
  describe "#get_environment" do
    it "prints a deprecation warning to STDERR" do
      comp = Vanagon::Component.new('env-test', {}, {})
      expect { comp.get_environment }
        .to output(/deprecated/).to_stderr
    end

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
      expect(comp.get_environment).to eq(': no environment variables defined')
    end
  end

  describe "#get_build_dir" do
    subject(:comp) do
      Vanagon::Component.new('build-dir-test', {}, {}).tap do |comp|
        comp.dirname = "build-dir-test"
      end
    end

    it "uses the dirname when no build_dir was set" do
      expect(comp.get_build_dir).to eq "build-dir-test"
    end

    it "joins the dirname and the build dir when a build_dir was set" do
      comp.build_dir = "cmake-build"
      expect(comp.get_build_dir).to eq File.join("build-dir-test", "cmake-build")
    end
  end
end
