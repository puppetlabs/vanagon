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

  describe "#get_source" do
    before :each do
      @workdir = Dir.mktmpdir
      @fake_tar = "file://spec/fixtures/files/fake_file.txt.tar.gz"
    end

    subject do
      # Initialize a new instance of Vanagon::Component and define a
      # new secondary source that's *uncompressed*. We can now reason about
      # this instance and test behavior for retrieving secondary sources.
      Vanagon::Component.new('build-dir-test', {}, {}).tap do |comp|
        comp.url = @fake_tar
      end
    end

    before do
      allow(subject)
        .to receive(:source)
        .and_return(OpenStruct.new(verify: true))
    end

    it "will not consider a non-rewritten URI as a mirror" do
      expect(subject.mirrors).to eq Set.new []
    end

    it "attempts to retrieve from a mirror before a canonical URI" do
      allow(subject)
        .to receive(:fetch_url)
        .and_return(false)

      allow(subject)
        .to receive(:fetch_mirrors)
        .and_return(true)

      expect(subject).to receive(:fetch_mirrors)
      expect(subject).not_to receive(:fetch_url)

      subject.get_source(@workdir)
    end

    it "retrieves from a canonical URI if mirrors are unavailable" do
      allow(subject)
        .to receive(:fetch_url)
        .and_return(true)

      # We expect #get_source to attempt to use a mirror...
      expect(subject).to receive(:fetch_mirrors).and_return(false)
      # But we also expect it to fail when it tries #mirrors.
      expect(subject).to receive(:fetch_url)
      subject.get_source(@workdir)
    end

    it 'retrieves from a canonical URI if VANAGON_USE_MIRRORS is set to "n"' do
      allow(ENV).to receive(:[]).with('VANAGON_USE_MIRRORS').and_return('n')
      allow(subject)
        .to receive(:fetch_url)
        .and_return(true)

      # We expect #get_source to skip mirrors
      expect(subject).not_to receive(:fetch_mirrors)
      expect(subject).to receive(:fetch_url)
      subject.get_source(@workdir)
    end
  end

  describe "#get_sources" do
    before :each do
      @workdir = Dir.mktmpdir
      @file_name = 'fake_file.txt'
      @fake_file = "file://spec/fixtures/files/#{@file_name}"
      @fake_erb_file = "file://spec/fixtures/files/#{@file_name}.erb"
      @fake_dir = 'fake_dir'
      @fake_tar = "file://spec/fixtures/files/#{@fake_dir}.tar.gz"
    end

    subject do
      # Initialize a new instance of Vanagon::Component and define a
      # new secondary source that's *uncompressed*. We can now reason about
      # this instance and test behavior for retrieving secondary sources.
      Vanagon::Component.new('build-dir-test', {}, {}).tap do |comp|
        comp.sources << OpenStruct.new(url: @fake_file)
        comp.mirrors << @fake_tar
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

    it "Performs an erb translation when erb: is true" do
      # Initialize a new instance of Vanagon::Component and define a
      # new secondary source that's *compressed*. We can now reason about
      # this instance and test behavior for retrieving secondary sources.
      plat = Vanagon::Platform::DSL.new('el-5-x86_64')
      plat.instance_eval("platform 'el-5-x86_64' do |plat| end")
      @platform = plat._platform

      comp = Vanagon::Component::DSL.new('build-dir-test', {}, @platform)
      comp.add_source  @fake_erb_file, erb: true
      subject = comp._component

      file_path = File.join(@workdir, File.basename(@fake_erb_file))
      expect(subject).to receive(:erb_file).with(Pathname.new(file_path), file_path.gsub('.erb', ''), true)
      subject.get_sources(@workdir)
    end

    it "Does not perform an erb transformation when erb: is false" do
      # Initialize a new instance of Vanagon::Component and define a
      # new secondary source that's *compressed*. We can now reason about
      # this instance and test behavior for retrieving secondary sources.
      plat = Vanagon::Platform::DSL.new('el-5-x86_64')
      plat.instance_eval("platform 'el-5-x86_64' do |plat| end")
      @platform = plat._platform

      comp = Vanagon::Component::DSL.new('build-dir-test', {}, @platform)
      comp.add_source  @fake_file, erb: false
      subject = comp._component

      expect(subject).to_not receive(:erb_file)
      subject.get_sources(@workdir)
    end

    it "Does not perform an erb transformation when erb: is nil (not set)" do
      # Initialize a new instance of Vanagon::Component and define a
      # new secondary source that's *compressed*. We can now reason about
      # this instance and test behavior for retrieving secondary sources.
      plat = Vanagon::Platform::DSL.new('el-5-x86_64')
      plat.instance_eval("platform 'el-5-x86_64' do |plat| end")
      @platform = plat._platform

      comp = Vanagon::Component::DSL.new('build-dir-test', {}, @platform)
      comp.add_source  @fake_file
      subject = comp._component

      expect(subject).to_not receive(:erb_file)
      subject.get_sources(@workdir)
    end
  end

  describe "#get_patches" do
    before :each do
      @workdir = Dir.mktmpdir
    end

    let(:platform) do
      plat = Vanagon::Platform::DSL.new('el-5-x86_64')
      plat.instance_eval("platform 'el-5-x86_64' do |plat| end")
      plat._platform
    end

    let(:component) { Vanagon::Component::DSL.new('patches-test', {}, platform) }

    context("when new patch file would overwrite existing patch file") do
      let(:patch_file) { 'path/to/test.patch' }

      before :each do
        allow(FileUtils).to receive(:mkdir_p)
        allow(FileUtils).to receive(:cp)

        expect(File).to receive(:exist?).with(File.join(@workdir, 'patches', File.basename(patch_file))).and_return(true)

        component.apply_patch(patch_file)
      end

      it "fails the build" do
        expect { component._component.get_patches(@workdir) }.to raise_error(Vanagon::Error, /duplicate patch files/i)
      end
    end
  end
end
