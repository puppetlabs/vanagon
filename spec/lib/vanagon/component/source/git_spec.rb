require 'vanagon/component/source/git'

describe "Vanagon::Component::Source::Git" do
  let (:url) { 'git://github.com/puppetlabs/facter' }
  let (:ref) { '2.2.0' }
  let (:workdir) { "/tmp" }

  describe "#dirname" do
    it "returns the name of the repo" do
      git_source = Vanagon::Component::Source::Git.new(url, ref, workdir)
      expect(git_source.dirname).to eq('facter')
    end

    it "returns the name of the repo and strips .git" do
      git_source = Vanagon::Component::Source::Git.new("#{url}.git", ref, workdir)
      expect(git_source.dirname).to eq('facter')
    end
  end
end
