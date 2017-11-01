require 'vanagon/component/source'

describe "Vanagon::Component::Source" do
  let(:klass) { Vanagon::Component::Source }

  describe ".source" do
    let(:unrecognized_uri) { "abcd://things" }
    let(:unrecognized_scheme) { "abcd" }
    let(:invalid_scheme) { "abcd|things" }

    let(:public_git) { "git://github.com/abcd/things" }
    let(:private_git) { "git@github.com:abcd/things" }
    let(:http_git) { "http://github.com/abcd/things" }
    let(:https_git) { "https://github.com/abcd/things" }

    let(:http_url) { "http://abcd/things" }
    let(:https_url) { "https://abcd/things" }

    let(:file_url) { "file://things" }

    let(:ref) { "cafebeef" }
    let(:sum) { "abcd1234" }
    let(:workdir) { Dir.mktmpdir }

    let(:original_git_url) { "git://things.and.stuff/foo-bar.git" }

    let(:original_http_url) { "http://things.and.stuff/foo.tar.gz" }

    it "fails on unrecognized URI schemes" do
      expect { klass.source(unrecognized_uri, workdir: workdir) }
        .to raise_error(Vanagon::Error)
    end

    it "fails on invalid URIs" do
      expect { klass.source(invalid_scheme, workdir: workdir) }
        .to raise_error(URI::InvalidURIError)
    end

    context "takes a Git repo" do
      before do
        allow_any_instance_of(Vanagon::Component::Source::Git)
          .to receive(:valid_remote?)
          .and_return(true)

        allow(Vanagon::Component::Source::Git)
          .to receive(:valid_remote?)
          .and_return(true)
      end

      it "returns a Git object for git@ triplet repositories" do
        expect(klass.source(private_git, ref: ref, workdir: workdir).class)
          .to eq Vanagon::Component::Source::Git
      end

      it "returns a Git object for git:// repositories" do
        expect(klass.source(public_git, ref: ref, workdir: workdir).class)
          .to eq Vanagon::Component::Source::Git
      end

      it "returns a Git object for http:// repositories" do
        expect(klass.source(http_git, ref: ref, workdir: workdir).class)
          .to eq Vanagon::Component::Source::Git
      end

      it "returns a Git object for https:// repositories" do
        expect(klass.source(https_git, ref: ref, workdir: workdir).class)
          .to eq Vanagon::Component::Source::Git
      end
    end

    context "takes a HTTP/HTTPS file" do
      before do
        allow(Vanagon::Component::Source::Http)
          .to receive(:valid_url?)
          .with(sum)
          .and_return(false)
      end

      it "returns an object of the correct type for http:// URLS" do
        allow(Vanagon::Component::Source::Http)
          .to receive(:valid_url?)
          .with(http_url)
          .and_return(true)
        expect(klass.source(http_url, sum: sum, workdir: workdir, sum_type: "md5").class)
          .to equal(Vanagon::Component::Source::Http)
      end

      it "returns an object of the correct type for https:// URLS" do
        allow(Vanagon::Component::Source::Http)
          .to receive(:valid_url?)
          .with(https_url)
          .and_return(true)
        expect(klass.source(https_url, sum: sum, workdir: workdir, sum_type: "md5").class)
          .to equal(Vanagon::Component::Source::Http)
      end
    end

    context "takes a local file" do
      before do
        allow_any_instance_of(Vanagon::Component::Source::Local)
          .to receive(:valid_file?)
          .and_return(true)

        allow(Vanagon::Component::Source::Local)
          .to receive(:valid_file?)
          .and_return(true)
      end

      it "returns an object of the correct type for file:// URLS" do
        expect(klass.source(file_url, sum: sum, workdir: workdir).class)
          .to eq Vanagon::Component::Source::Local
      end
    end
  end
end
