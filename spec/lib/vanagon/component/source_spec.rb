require 'vanagon/component/source'

describe "Vanagon::Component::Source" do
  describe "self.source" do
    let (:unrecognized_scheme) { "abcd://things" }
    let (:invalid_scheme) { "abcd|things" }
    let (:public_git) { "git://github.com/abcd/things" }
    let (:private_git) { "git@github.com:abcd/things" }
    let (:http_url) { "http://abcd/things" }
    let (:https_url) { "https://abcd/things" }

    let (:ref) { "1.2.3" }
    let (:sum) { "abcd1234" }
    let (:workdir) { "/tmp" }

    it "fails on unrecognized uri schemes" do
      expect { Vanagon::Component::Source.source(unrecognized_scheme, {}, workdir) }.to raise_error(RuntimeError)
    end

    it "fails on invalid uris" do
      expect { Vanagon::Component::Source.source(invalid_scheme, {}, workdir) }.to raise_error(RuntimeError)
    end

    it "returns an object of the correct type for git@ urls" do
      expect(Vanagon::Component::Source.source(private_git, {:ref => ref }, workdir).class).to equal(Vanagon::Component::Source::Git)
    end

    it "returns an object of the correct type for git:// urls" do
      expect(Vanagon::Component::Source.source(public_git, {:ref => ref }, workdir).class).to equal(Vanagon::Component::Source::Git)
    end

    it "returns an object of the correct type for http:// urls" do
      expect(Vanagon::Component::Source.source(http_url, {:sum => sum }, workdir).class).to equal(Vanagon::Component::Source::Http)
    end

    it "returns an object of the correct type for https:// urls" do
      expect(Vanagon::Component::Source.source(https_url, {:sum => sum }, workdir).class).to equal(Vanagon::Component::Source::Http)
    end
  end
end
