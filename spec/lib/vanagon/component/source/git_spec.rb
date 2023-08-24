require 'vanagon/component/source/git'

describe "Vanagon::Component::Source::Git" do
  before :all do
    @klass = Vanagon::Component::Source::Git
    # This repo will not be cloned over the network
    @url = 'https://github.com/puppetlabs/facter.git'
    # This path will not be created on disk
    @local_url = "file://#{Dir.tmpdir}/puppet-agent"
    @ref_tag = 'refs/tags/2.2.0'
    @workdir = nil
  end

  context 'with a github https: URI' do
    let(:github_archive_uri) do
      'https://github.com/2ndQuadrant/pglogical/archive/a_file_name.tar.gz'
    end
    let(:github_releases_uri) do
      'https://github.com/libffi/libffi/releases/download/v3.4.3/libffi-3.4.3.tar.gz'
    end
    let(:github_tarball_uri) do
      'https://github.com/Baeldung/kotlin-tutorials/tarball/main'
    end
    let(:github_zipball_uri) do
      'https://github.com/Baeldung/kotlin-tutorials/zipball/master'
    end
    let(:github_actual_tarball_uri) do
      'https://github.com/puppetlabs/puppet/archive/refs/tags/8.2.0.tar.gz'
    end
    let(:github_actual_tarball_with_unexpected_path_uri) do
      'https://github.com/puppetlabs/puppet/something/refs/tags/8.2.0.tar.gz'
    end
    let(:github_actual_zipball_uri) do
      'https://github.com/puppetlabs/puppet/archive/refs/tags/8.2.0.zip'
    end
    let(:github_actual_zipball_with_unexpected_path_uri) do
      'https://github.com/puppetlabs/puppet/something/refs/tags/8.2.0.zip'
    end
    let(:github_repo_uri) do
      'https://github.com/cameronmcnz/rock-paper-scissors'
    end
    let(:github_repo_dotgit_uri) do
      'https://github.com/cameronmcnz/rock-paper-scissors.git'
    end

    it "flags github archive uris as not valid repos" do
      expect(Vanagon::Component::Source::Git.valid_remote?(github_archive_uri)).to be false
    end

    it "flags github releases uris as not valid repos" do
      expect(Vanagon::Component::Source::Git.valid_remote?(github_releases_uri)).to be false
    end

    it "flags github tarball uris as not valid repos" do
      expect(Vanagon::Component::Source::Git.valid_remote?(github_tarball_uri)).to be false
    end

    it "flags github actual tarball uris as not valid repos" do
      expect(Vanagon::Component::Source::Git.valid_remote?(github_actual_tarball_uri)).to be false
    end

    it "flags github actual tarball uris with an unexpected path as not valid repos" do
      expect(Vanagon::Component::Source::Git.valid_remote?(github_actual_tarball_with_unexpected_path_uri)).to be false
    end

    it "flags git zipball uris as not valid repos" do
      expect(Vanagon::Component::Source::Git.valid_remote?(github_zipball_uri)).to be false
    end

    it "flags github actual tarball uris as not valid repos" do
      expect(Vanagon::Component::Source::Git.valid_remote?(github_actual_zipball_uri)).to be false
    end

    it "flags github actual tarball uris with an unexpected path as not valid repos" do
      expect(Vanagon::Component::Source::Git.valid_remote?(github_actual_zipball_with_unexpected_path_uri)).to be false
    end

    it "identifies git generic uris as valid repos" do
      expect(Vanagon::Component::Source::Git.valid_remote?(github_repo_uri)).to be true
    end

    it "identifies .git repo uris as valid repos" do
      expect(Vanagon::Component::Source::Git.valid_remote?(github_repo_dotgit_uri)).to be true
    end
  end

  context 'with other non-github URIs' do
    before :each do
      allow(Vanagon::Component::Source::Git).to receive(:valid_remote?).and_return(true)
      allow(File).to receive(:realpath).and_return(@workdir)
    end

    describe "#initialize" do
      it "raises error on initialization with an invalid repo" do
        # Ensure initializing a repo fails without calling over the network
        allow(Vanagon::Component::Source::Git).to receive(:valid_remote?).and_return(false)

        expect { @klass.new(@url, ref: @ref_tag, workdir: @workdir) }
          .to raise_error(Vanagon::InvalidRepo)
      end

      it "uses the realpath of the workdir if we're in a symlinked dir" do
        expect(File).to receive(:realpath).and_return("/tmp/bar")
        git_source = @klass.new(@local_url, ref: @ref_tag, workdir: "/tmp/foo")
        expect(git_source.workdir).to eq('/tmp/bar')
      end

      it "with no clone options should be empty" do
        git_source = @klass.new(@local_url, ref: @ref_tag, workdir: "/tmp/foo")
        expect(git_source.clone_options).to be {}
      end

      it "add clone options depth and branch" do
        expected_clone_options = {branch: 'bar', depth: 50 }
        git_source = @klass.new(@local_url, ref: @ref_tag,
                                workdir: "/tmp/foo", clone_options: expected_clone_options)
        expect(git_source.clone_options).to  be(expected_clone_options)
      end
    end

    describe "#clone" do
      before :each do
        clone = double(Git::Base)
        @file_path = "/tmp/foo"
        allow(Git).to receive(:clone).and_return(clone)
        expect(File).to receive(:realpath).and_return(@file_path)
      end

      it "repository" do
        git_source = @klass.new(@url, ref: @ref_tag, workdir: "/tmp/foo")
        expect(Git).to receive(:clone).with(git_source.url, git_source.dirname, path: @file_path)
        git_source.clone
      end

      it "a particular branch with a depth" do
        expected_clone_options = {:branch => "foo", :depth => 50 }
        git_source = @klass.new(@url, ref: @ref_tag, workdir: "/tmp/foo",
                                clone_options: expected_clone_options)
        expect(Git)
          .to receive(:clone)
          .with(git_source.url, git_source.dirname, path: @file_path, **expected_clone_options)
        git_source.clone
      end

      it 'uses a custom dirname' do
        git_source = @klass.new(@url, ref: @ref_tag, workdir: "/tmp/foo", dirname: 'facter-ng')
        expect(Git).to receive(:clone).with(git_source.url, 'facter-ng', path: @file_path)
        git_source.clone
      end
    end

    describe "#dirname" do
      it "returns the name of the repo" do
        git_source = @klass.new(@local_url, ref: @ref_tag, workdir: @workdir)
        expect(git_source.dirname).to eq('puppet-agent')
      end

      it "returns the name of the repo and strips .git" do
        git_source = @klass.new(@url, ref: @ref_tag, workdir: @workdir)
        expect(git_source.dirname).to eq('facter')
      end

      it "returns @dirname if is set" do
        git_source = @klass.new(@url, ref: @ref_tag, workdir: @workdir, dirname: 'facter-ng')
        expect(git_source.dirname).to eq('facter-ng')
      end
    end

    describe "#ref" do
      it "returns a default value of HEAD when no explicit Git reference is provided" do
        git_source = @klass.new(@url, workdir: @workdir)
        expect(git_source.ref).to eq('HEAD')
      end

      it "returns a default value of HEAD when Git reference is nil" do
        git_source = @klass.new(@url, ref: nil, workdir: @workdir)
        expect(git_source.ref).to eq('HEAD')
      end
    end
  end
end
