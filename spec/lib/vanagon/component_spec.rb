require 'vanagon/component'

describe "Vanagon::Component" do
  describe "#get_environment" do
    subject { Vanagon::Component.new('env-test', {}, {}) }

    it "prints a deprecation warning to STDERR" do
      expect { subject.get_environment }.to output(/deprecated/).to_stderr
    end

    it "returns a makefile compatible environment" do
      subject.environment = {'PATH' => '/usr/local/bin', 'CFLAGS' => '-O3'}
      expect(subject.get_environment).to eq %(PATH="/usr/local/bin" CFLAGS="-O3")
    end

    it 'merges against the existing environment' do
      subject.environment = {'PATH' => '/usr/bin', 'CFLAGS' => '-I /usr/local/bin'}
      expect(subject.get_environment).to eq %(PATH="/usr/bin" CFLAGS="-I /usr/local/bin")
    end

    it 'returns : for an empty environment' do
      expect(subject.get_environment).to eq %(: no environment variables defined)
    end
  end

  describe "#get_build_dir" do
    subject do
      Vanagon::Component.new('build-dir-test', {}, {}).tap do |comp|
        comp.dirname = "build-dir-test"
      end
    end

    it "uses the dirname when no build_dir was set" do
      expect(subject.get_build_dir).to eq "build-dir-test"
    end

    it "joins the dirname and the build dir when a build_dir was set" do
      subject.build_dir = "cmake-build"
      expect(subject.get_build_dir).to eq File.join("build-dir-test", "cmake-build")
    end
  end

  describe "#get_sources" do
    before :each do
      @workdir = Dir.mktmpdir
      @file_name = 'fake_file.txt'
      @fake_file = "file://spec/fixtures/files/#{@file_name}"
    end

    subject do
      # Initialize a new instance of Vanagon::Component and define a
      # new secondary source. We can now reason about this instance and
      # test behavior for retrieving secondary sources.
      Vanagon::Component.new('build-dir-test', {}, {}).tap do |comp|
        comp.sources << OpenStruct.new(url: @fake_file)
      end
    end

    it "copies secondary sources into the workdir" do
      subject.get_sources(@workdir)
      expect(File.exist?(File.join(@workdir, @file_name))).to be true
    end
  end
end
