require 'vanagon/component/source/git'

describe "Vanagon::Component::Source::Http" do
  let (:base_url) { 'http://buildsources.delivery.puppetlabs.net' }
  let (:file_base) { 'thing-1.2.3' }
  let (:tar_filename) { 'thing-1.2.3.tar.gz' }
  let (:tar_url) { "#{base_url}/#{tar_filename}" }
  let (:tar_dirname) { 'thing-1.2.3' }
  let (:plaintext_filename) { 'thing-1.2.3.txt' }
  let (:plaintext_url) { "#{base_url}/#{plaintext_filename}" }
  let (:plaintext_dirname) { './' }
  let (:md5sum) { 'abcdssasasa' }
  let (:workdir) { "/tmp" }

  describe "#dirname" do
    it "returns the name of the tarball, minus extension for archives" do
      http_source = Vanagon::Component::Source::Http.new(tar_url, md5sum, workdir)
      expect(http_source).to receive(:download).and_return(tar_filename)
      http_source.fetch
      expect(http_source.dirname).to eq(tar_dirname)
    end

    it "returns the current directory for non-archive files" do
      http_source = Vanagon::Component::Source::Http.new(plaintext_url, md5sum, workdir)
      expect(http_source).to receive(:download).and_return(plaintext_filename)
      http_source.fetch
      expect(http_source.dirname).to eq(plaintext_dirname)
    end
  end

  describe "#get_extension" do
    it "returns the extension for valid extensions" do
      (Vanagon::Component::Source::Http::ARCHIVE_EXTENSIONS + Vanagon::Component::Source::Http::NON_ARCHIVE_EXTENSIONS).each do |ext|
        filename = "#{file_base}#{ext}"
        url = File.join(base_url, filename)
        http_source = Vanagon::Component::Source::Http.new(url, md5sum, workdir)
        expect(http_source).to receive(:download).and_return(filename)
        http_source.fetch
        expect(http_source.get_extension).to eq(ext)
      end
    end
  end
end
