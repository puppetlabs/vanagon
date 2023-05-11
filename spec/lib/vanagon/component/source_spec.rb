require 'vanagon/component/source'

describe "Vanagon::Component::Source" do
  let(:klass) { Vanagon::Component::Source }

  describe ".source" do
    let(:unrecognized_uri) { "abcd://things" }
    let(:unrecognized_scheme) { "abcd" }
    let(:invalid_scheme) { "abcd|things" }

    let(:private_git) { "git@github.com:abcd/things" }
    let(:http_git) { "http://github.com/abcd/things" }
    let(:https_git) { "https://github.com/abcd/things" }
    let(:git_prefixed_http) { "git:http://github.com/abcd/things" }

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

    context "with a Git repo" do
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

      it "returns a Git object for http:// repositories" do
        expect(klass.source(http_git, ref: ref, workdir: workdir).class)
          .to eq Vanagon::Component::Source::Git
      end

      it "returns a Git object for https:// repositories" do
        expect(klass.source(https_git, ref: ref, workdir: workdir).class)
          .to eq Vanagon::Component::Source::Git
      end

      it "returns a Git object for git:http:// repositories" do
        component_source = klass.source(git_prefixed_http, ref: ref, workdir: workdir)
        expect(component_source.class).to eq Vanagon::Component::Source::Git
      end

      it "returns a Git url for git:http:// repositories" do
        component_source = klass.source(git_prefixed_http, ref: ref, workdir: workdir)
        expect(component_source.url.to_s).to eq 'http://github.com/abcd/things'
      end
    end

    context "with a HTTP/HTTPS file" do
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

    context "with a local file" do
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

  describe "#determine_source_type" do
    context 'with a github https: URI' do

      let(:github_archive_uri) do
        'https://github.com/2ndQuadrant/pglogical/archive/a_file_name.tar.gz'
      end
      let(:github_tarball_uri) do
        'https://github.com/Baeldung/kotlin-tutorials/tarball/main'
      end
      let(:github_zipball_uri) do
        'https://github.com/Baeldung/kotlin-tutorials/zipball/master'
      end
      let(:github_repo_uri) do
        'https://github.com/cameronmcnz/rock-paper-scissors'
      end
      let(:github_repo_dotgit_uri) do
        'https://github.com/cameronmcnz/rock-paper-scissors.git'
      end

      it "identifies github archive uris" do
        stub_request(:head, github_archive_uri).with(
          headers: {
       	    'Accept' => '*/*',
       	    'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
       	    'Host' => 'github.com',
       	    'User-Agent' => 'Ruby'
          }
        ).to_return(status: 200, body: "", headers: {})

        expect(Vanagon::Component::Source.determine_source_type(github_archive_uri))
          .to eq(:http)
      end

      it "identifies github tarball uris" do
        stub_request(:head, github_tarball_uri).with(
          headers: {
       	    'Accept' => '*/*',
       	    'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
       	    'Host' => 'github.com',
       	    'User-Agent' => 'Ruby'
          }
        ).to_return(status: 200, body: "", headers: {})

        expect(Vanagon::Component::Source.determine_source_type(github_tarball_uri))
          .to eq(:http)
      end

      it "identifies github zipball uris" do
        stub_request(:head, github_zipball_uri).with(
          headers: {
       	    'Accept' => '*/*',
       	    'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
       	    'Host' => 'github.com',
       	    'User-Agent' => 'Ruby'
          }
        ).to_return(status: 200, body: "", headers: {})

        expect(Vanagon::Component::Source.determine_source_type(github_zipball_uri))
          .to eq(:http)
      end

      it "identifies github generic repo uris" do
        expect(Vanagon::Component::Source.determine_source_type(github_repo_uri))
          .to eq(:git)
      end

      it "identifies github .git repo uris" do
        expect(Vanagon::Component::Source.determine_source_type(github_repo_dotgit_uri))
          .to eq(:git)
      end
    end
  end
end
