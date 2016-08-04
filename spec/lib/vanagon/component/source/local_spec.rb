require 'vanagon/component/source/git'

describe "Vanagon::Component::Source::File" do
  let (:file_base) { 'file://spec/fixtures/files/fake_file_ext' }
  let (:tar_filename) { 'file://spec/fixtures/files/fake_dir.tar.gz' }
  let (:plaintext_filename) { 'file://spec/fixtures/files/fake_file.txt' }
  let (:workdir) { "/tmp" }

  describe "#fetch" do
    it "puts the source file in to the workdir" do
      file = Vanagon::Component::Source::Local.new(plaintext_filename, workdir: workdir)
      file.fetch
      expect(File).to exist("#{workdir}/fake_file.txt")
    end
  end

  describe "#dirname" do
    it "returns the name of the tarball, minus extension for archives" do
      file = Vanagon::Component::Source::Local.new(tar_filename, workdir: workdir)
      file.fetch
      expect(file.dirname).to eq("fake_dir")
    end

    it "returns the current directory for non-archive files" do
      file = Vanagon::Component::Source::Local.new(plaintext_filename, workdir: workdir)
      file.fetch
      expect(file.dirname).to eq("./")
    end
  end

  describe "#extension" do
    it "returns the extension for valid extensions" do
      Vanagon::Component::Source::Local.archive_extensions.each do |ext|
        filename = "#{file_base}#{ext}"
        file = Vanagon::Component::Source::Local.new(filename, workdir: workdir)
        file.fetch
        expect(file.extension).to eq(ext)
      end
    end
  end
end
