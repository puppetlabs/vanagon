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
  let (:sha256sum) { 'foobarbaz' }
  let (:sha512sum) { 'teststring' }
  let (:workdir) { Dir.mktmpdir }

  describe "#initialize" do
    it "fails with a bad sum_type" do
      expect { Vanagon::Component::Source::Http.new(plaintext_url, sum: md5sum, workdir: workdir, sum_type: "md4") }
        .to raise_error(RuntimeError)
    end
  end

  describe "#dirname" do
    it "returns the name of the tarball, minus extension for archives" do
      http_source = Vanagon::Component::Source::Http.new(tar_url, sum: md5sum, workdir: workdir, sum_type: "md5")
      expect(http_source).to receive(:download).and_return(tar_filename)
      http_source.fetch
      expect(http_source.dirname).to eq(tar_dirname)
    end

    it "returns the current directory for non-archive files" do
      http_source = Vanagon::Component::Source::Http.new(plaintext_url, sum: md5sum, workdir: workdir, sum_type: "md5")
      expect(http_source).to receive(:download).and_return(plaintext_filename)
      http_source.fetch
      expect(http_source.dirname).to eq(plaintext_dirname)
    end
  end

  describe "#verify" do
    it "calls md5 digest when it's supposed to" do
      allow_any_instance_of(Digest::MD5).to receive(:file).and_return(Digest::MD5.new)
      allow_any_instance_of(Digest::MD5).to receive(:hexdigest).and_return(md5sum)
      http_source = Vanagon::Component::Source::Http.new(plaintext_url, sum: md5sum, workdir: workdir, sum_type: "md5")
      expect(http_source).to receive(:download).and_return(plaintext_filename)
      http_source.fetch
      http_source.verify
    end

    it "calls sha256 digest when it's supposed to" do
      allow_any_instance_of(Digest::SHA256).to receive(:file).and_return(Digest::SHA256.new)
      allow_any_instance_of(Digest::SHA256).to receive(:hexdigest).and_return(sha256sum)
      http_source = Vanagon::Component::Source::Http.new(plaintext_url, sum: sha256sum, workdir: workdir, sum_type: "sha256")
      expect(http_source).to receive(:download).and_return(plaintext_filename)
      http_source.fetch
      http_source.verify
    end

    it "calls sha512 digest when it's supposed to" do
      allow_any_instance_of(Digest::SHA512).to receive(:file).and_return(Digest::SHA512.new)
      allow_any_instance_of(Digest::SHA512).to receive(:hexdigest).and_return(sha512sum)
      http_source = Vanagon::Component::Source::Http.new(plaintext_url, sum: sha512sum, workdir: workdir, sum_type: "sha512")
      expect(http_source).to receive(:download).and_return(plaintext_filename)
      http_source.fetch
      http_source.verify
    end
  end
end
