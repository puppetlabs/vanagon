require 'vanagon/component/source/git'

describe "Vanagon::Component::Source::Git" do
  let (:url) { 'git://github.com/puppetlabs/facter' }
  let (:ref) { '2.2.0' }
  let (:workdir) { "/tmp" }

  describe "#dirname" do
    after(:each) { %x(rm -rf #{workdir}/facter) }
    it "returns the name of the repo" do
      git_source = Vanagon::Component::Source::Git.new(url, ref, workdir)
      expect(git_source.dirname).to eq('facter')
    end

    it "returns the name of the repo and strips .git" do
      git_source = Vanagon::Component::Source::Git.new("#{url}.git", ref, workdir)
      expect(git_source.dirname).to eq('facter')
    end
  end

  describe "#fetch" do
    after(:each) { %x(rm -rf #{workdir}/facter) }
    it "raises error on clone failure" do
      #this test has a spelling error for the git repo        V      this is on purpose
      git_source = Vanagon::Component::Source::Git.new("#{url}l.git", ref, workdir)
      expect { git_source.fetch }.to raise_error(RuntimeError, "git clone #{url}l.git failed")
    end
    it "raises error on checkout failure" do
      git_source = Vanagon::Component::Source::Git.new("#{url}", "999.9.9", workdir)
      expect { git_source.fetch }.to raise_error(RuntimeError, "git checkout 999.9.9 failed")
    end
  end
end
