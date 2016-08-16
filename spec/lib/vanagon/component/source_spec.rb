require 'vanagon/component/source'

describe "Vanagon::Component::Source" do
  let(:klass) { Vanagon::Component::Source }
  before(:each) { klass.rewrite_rules.clear }

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
    let(:workdir) { "/tmp" }

    let(:original_git_url) { "git://things.and.stuff/foo-bar.git" }
    let(:rewritten_git_url) { "git://things.end.stuff/foo-ber.git" }

    let(:original_http_url) { "http://things.and.stuff/foo.tar.gz" }
    let(:rewritten_http_url) { "http://buildsources.delivery.puppetlabs.net/foo.tar.gz" }

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

      it "rewrites git:// URLs" do
        proc_rule = Proc.new { |url| url.gsub('a', 'e') }
        klass.register_rewrite_rule('git', proc_rule)
        # Vanagon::Component::Source::Git#url returns a URI object
        # so to check its value, we cast it to a simple string. It's
        # hacky for sure, but seems less diagreeable than mangling the
        # return value in the class itself.
        expect(klass.source(original_git_url, ref: ref, workdir: workdir).url.to_s)
        .to eq rewritten_git_url
      end
    end

    context "takes a HTTP/HTTPS file" do
      before do
        allow_any_instance_of(Vanagon::Component::Source::Http)
          .to receive(:valid_url?)
          .and_return(true)

        allow(Vanagon::Component::Source::Http)
          .to receive(:valid_url?)
          .and_return(true)
      end

      it "returns an object of the correct type for http:// URLS" do
        expect(klass.source(http_url, sum: sum, workdir: workdir, sum_type: "md5").class)
          .to equal(Vanagon::Component::Source::Http)
      end

      it "returns an object of the correct type for https:// URLS" do
        expect(klass.source(https_url, sum: sum, workdir: workdir, sum_type: "md5").class)
          .to equal(Vanagon::Component::Source::Http)
      end

      before do
        klass.register_rewrite_rule 'http',
          'http://buildsources.delivery.puppetlabs.net'
      end
      it "applies rewrite rules to HTTP URLs" do
        expect(klass.source(original_http_url, sum: sum, workdir: workdir, sum_type: "md5").url)
          .to eq(rewritten_http_url)
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

  describe ".rewrite" do
    let(:simple_rule) { Proc.new {|url| url.gsub('a', 'e') } }
    let(:complex_rule) do
      Proc.new do |url|
        match = url.match(/github.com\/(.*)$/)
        "git://github.delivery.puppetlabs.net/#{match[1].gsub('/', '-')}" if match
      end
    end

    it 'replaces the first section of a url with a string if string is given' do
      klass.register_rewrite_rule('http', 'http://buildsources.delivery.puppetlabs.net')

      expect(klass.rewrite('http://things.and.stuff/foo.tar.gz', 'http'))
        .to eq('http://buildsources.delivery.puppetlabs.net/foo.tar.gz')
    end

    it 'applies the rule to the url if a proc is given as the rule' do
      klass.register_rewrite_rule('http', simple_rule)

      expect(klass.rewrite('http://things.and.stuff/foo.tar.gz', 'http'))
        .to eq('http://things.end.stuff/foo.ter.gz')
    end

    it 'applies the rule to the url if a proc is given as the rule' do
      klass.register_rewrite_rule('git', complex_rule)

      expect(klass.rewrite('git://github.com/puppetlabs/facter', 'git'))
        .to eq('git://github.delivery.puppetlabs.net/puppetlabs-facter')
    end
  end

  describe ".register_rewrite_rule" do
    it 'only accepts Proc and String as rule types' do
      expect { klass.register_rewrite_rule('http', 5) }
        .to raise_error(Vanagon::Error)
    end

    it 'rejects invalid protocols' do
      expect { klass.register_rewrite_rule('gopher', 'abcd') }
        .to raise_error Vanagon::Error
    end

    before { klass.register_rewrite_rule('http', 'http://buildsources.delivery.puppetlabs.net') }
    it 'registers the rule for the given protocol' do
      expect(klass.rewrite_rules)
        .to eq({'http' => 'http://buildsources.delivery.puppetlabs.net'})
    end
  end
end
