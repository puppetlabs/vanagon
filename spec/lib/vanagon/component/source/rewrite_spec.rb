require 'vanagon/component/source'

describe "Vanagon::Component::Source::Rewrite" do
  let(:klass) { Vanagon::Component::Source::Rewrite }
  before(:each) { klass.rewrite_rules.clear }

  describe ".parse_and_rewrite" do
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
