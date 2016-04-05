require 'vanagon/component/source/git'

describe "Vanagon::Component::Source::File" do
  let (:file_base) { 'file://spec/fixtures/files/fake_file_ext' }
  let (:tar_filename) { 'file://spec/fixtures/files/fake_dir.tar.gz' }
  let (:plaintext_filename) { 'file://spec/fixtures/files/fake_file.txt' }
  let (:workdir) { "/tmp" }

  describe "#fetch" do
    it "puts the source file in to the workdir" do
      file = Vanagon::Component::Source::LocalSource.new(plaintext_filename, workdir)
      file.fetch
      expect(File).to exist("#{workdir}/fake_file.txt")
    end
  end

  describe "#dirname" do
    it "returns the name of the tarball, minus extension for archives" do
      file = Vanagon::Component::Source::LocalSource.new(tar_filename, workdir)
      file.fetch
      expect(file.dirname).to eq("fake_dir")
    end

    it "returns the current directory for non-archive files" do
      file = Vanagon::Component::Source::LocalSource.new(plaintext_filename, workdir)
      file.fetch
      expect(file.dirname).to eq("./")
    end
  end

  describe "#get_extension" do
    it "returns the extension for valid extensions" do
      Vanagon::Component::Source::LocalSource::ARCHIVE_EXTENSIONS.each do |ext|
        filename = "#{file_base}#{ext}"
        file = Vanagon::Component::Source::LocalSource.new(filename, workdir)
        file.fetch
        expect(file.get_extension).to eq(ext)
      end
    end
  end
end