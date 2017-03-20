require 'vanagon/component'
require 'vanagon/platform'

describe "Vanagon::Component" do
  describe "#get_environment" do
    subject { Vanagon::Component.new('env-test', {}, {}) }

    it "prints a deprecation warning to STDERR" do
      expect { subject.get_environment }.to output(/deprecated/).to_stderr
    end

    it "returns a makefile compatible environment" do
      subject.environment = {'PATH' => '/usr/local/bin', 'CFLAGS' => '-O3'}
      expect(subject.get_environment)
        .to eq [%(export PATH="/usr/local/bin"), %(export CFLAGS="-O3")]
    end

    it 'merges against the existing environment' do
      subject.environment = {'PATH' => '/usr/bin', 'CFLAGS' => '-I /usr/local/bin'}
      expect(subject.get_environment)
        .to eq [%(export PATH="/usr/bin"), %(export CFLAGS="-I /usr/local/bin")]
    end

    it 'returns : for an empty environment' do
      expect(subject.get_environment)
        .to eq %(: no environment variables defined)
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
      @fake_dir = 'fake_dir'
      @fake_tar = "file://spec/fixtures/files/#{@fake_dir}.tar.gz"
    end

    subject do
      # Initialize a new instance of Vanagon::Component and define a
      # new secondary source that's *uncompressed*. We can now reason about 
      # this instance and test behavior for retrieving secondary sources.
      Vanagon::Component.new('build-dir-test', {}, {}).tap do |comp|
        comp.sources << OpenStruct.new(url: @fake_file)
      end
    end  

    it "copies uncompressed secondary sources into the workdir" do
      subject.get_sources(@workdir)
      expect(File.exist?(File.join(@workdir, @file_name))).to be true
    end  

    subject do
      # Initialize a new instance of Vanagon::Component and define a
      # new secondary source that's *compressed*. We can now reason about
      # this instance and test behavior for retrieving secondary sources.
      plat = Vanagon::Platform::DSL.new('el-5-x86_64')
      plat.instance_eval("platform 'el-5-x86_64' do |plat| end")
      @platform = plat._platform

      comp = Vanagon::Component::DSL.new('build-dir-test', {}, @platform)
      comp.add_source @fake_file
      comp.add_source @fake_tar
      comp._component
    end

    it "copies compressed secondary sources into the workdir" do
      subject.get_sources(@workdir)
      expect(File.exist?(File.join(@workdir, @file_name))).to be true
      # make sure that our secondary source(s) made it into the workdir
      expect(File.exist?(File.join(@workdir, "#{@fake_dir}.tar.gz"))).to be true
      expect(subject.extract_with.join(" && ")).to match "#{@fake_dir}.tar.gz"
    end
  end
end
