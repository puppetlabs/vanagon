require 'vanagon/component/source/git'

describe "Vanagon::Component::Source::Git" do
  let(:klass) { Vanagon::Component::Source::Git }
  let(:url) { 'git://github.com/puppetlabs/facter' }
  let(:ref_tag) { 'refs/tags/2.2.0' }
  let(:bad_sha) { 'FEEDBEEF' }
  let(:workdir) { ENV["TMPDIR"] || "/tmp" }

  after(:each) { %x(rm -rf #{workdir}/facter) }

  describe "#initialize" do
    it "raises error on initialization with an invalid repo" do
      # this test has a spelling error for the git repo
      # * this is on purpose *
      expect { klass.new("#{url}l.git", ref: ref_tag, workdir: workdir) }
        .to raise_error Vanagon::InvalidRepo
    end
  end

  describe "#dirname" do
    it "returns the name of the repo" do
      git_source = klass.new(url, ref: ref_tag, workdir: workdir)
      expect(git_source.dirname)
        .to eq('facter')
    end

    it "returns the name of the repo and strips .git" do
      git_source = klass.new("#{url}.git", ref: ref_tag, workdir: workdir)
      expect(git_source.dirname)
        .to eq('facter')
    end
  end

  describe "#fetch" do
    it "raises an error on checkout failure with a bad SHA" do
      expect { klass.new("#{url}", ref: bad_sha, workdir: workdir).fetch }
        .to raise_error Vanagon::CheckoutFailed
    end
  end
end
