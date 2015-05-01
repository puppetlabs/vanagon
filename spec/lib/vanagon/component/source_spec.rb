require 'vanagon/component/source'

describe "Vanagon::Component::Source" do
  before(:each) do
    Vanagon::Component::Source.class_variable_set(:@@rewrite_rule, {})
  end

  describe "self.source" do
    let (:unrecognized_scheme) { "abcd://things" }
    let (:invalid_scheme) { "abcd|things" }
    let (:public_git) { "git://github.com/abcd/things" }
    let (:private_git) { "git@github.com:abcd/things" }
    let (:http_url) { "http://abcd/things" }
    let (:https_url) { "https://abcd/things" }
    let (:file_url) { "file://things" }

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

    it "returns an object of the correct type for file:// urls" do
      expect(Vanagon::Component::Source.source(file_url, {:sum => sum }, workdir).class).to equal(Vanagon::Component::Source::Http)
    end

    it "applies any rewrite rules before defining an http Source" do
      Vanagon::Component::Source.register_rewrite_rule('http', 'http://buildsources.delivery.puppetlabs.net')
      expect(Vanagon::Component::Source.source('http://things.and.stuff/foo.tar.gz', {:sum => sum }, workdir).url).to eq('http://buildsources.delivery.puppetlabs.net/foo.tar.gz')
    end

    it "applies any rewrite rules before defining an http Source" do
      Vanagon::Component::Source.register_rewrite_rule('git', Proc.new {|url| url.gsub('a', 'e') })
      expect(Vanagon::Component::Source.source('git://things.and.stuff/foo-bar.git', {:ref => ref }, workdir).url).to eq('git://things.end.stuff/foo-ber.git')
    end
  end

  describe "self.rewrite" do
    let(:simple_rule) { Proc.new {|url| url.gsub('a', 'e') } }
    let(:complex_rule) do
      Proc.new { |url|
        match = url.match(/github.com\/(.*)$/)
        "git://github.delivery.puppetlabs.net/#{match[1].gsub('/', '-')}" if match
      }
    end

    it 'replaces the first section of a url with a string if string is given' do
      Vanagon::Component::Source.register_rewrite_rule('http', 'http://buildsources.delivery.puppetlabs.net')
      expect(Vanagon::Component::Source.rewrite('http://things.and.stuff/foo.tar.gz', 'http')).to eq('http://buildsources.delivery.puppetlabs.net/foo.tar.gz')
    end

    it 'applies the rule to the url if a proc is given as the rule' do
      Vanagon::Component::Source.register_rewrite_rule('http', simple_rule)
      expect(Vanagon::Component::Source.rewrite('http://things.and.stuff/foo.tar.gz', 'http')).to eq('http://things.end.stuff/foo.ter.gz')
    end

    it 'applies the rule to the url if a proc is given as the rule' do
      Vanagon::Component::Source.register_rewrite_rule('git', complex_rule)
      expect(Vanagon::Component::Source.rewrite('git://github.com/puppetlabs/facter', 'git')).to eq('git://github.delivery.puppetlabs.net/puppetlabs-facter')
    end
  end

  describe "self.register_rewrite_rule" do
    it 'only accepts Proc and String as rule types' do
      expect{Vanagon::Component::Source.register_rewrite_rule('http', 5)}.to raise_error(Vanagon::Error)
    end

    it 'rejects invalid protocols' do
      expect{Vanagon::Component::Source.register_rewrite_rule('gopher', 'abcd')}.to raise_error(Vanagon::Error)
    end

    it 'registers the rule for the given protocol' do
      Vanagon::Component::Source.register_rewrite_rule('http', 'http://buildsources.delivery.puppetlabs.net')
      expect(Vanagon::Component::Source.class_variable_get(:@@rewrite_rule)).to eq({'http' => 'http://buildsources.delivery.puppetlabs.net'})
    end
  end
end
