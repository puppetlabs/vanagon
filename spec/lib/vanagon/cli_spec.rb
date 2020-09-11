require 'vanagon/cli'

##
## Ignore the CLI calling 'exit'
##
RSpec.configure do |rspec|
  rspec.around(:example) do |ex|
    begin
      ex.run
    rescue SystemExit => e
      puts "Got SystemExit: #{e.inspect}. Ignoring"
    end
  end
end

describe Vanagon::CLI do
  describe "options that don't take a value" do
    [:skipcheck, :verbose].each do |flag|
      it "can create an option parser that accepts the #{flag} flag" do
        subject = described_class.new
        expect(subject.parse!(%W[build --#{flag} project platform])).to have_key(flag)
      end
    end

    describe "short options" do
      [["v", :verbose]].each do |short, long|
        it "maps the short option #{short} to #{long}" do
          subject = described_class.new
          expect(subject.parse!(%W[build -#{short} project platform])).to include(long => true)
        end
      end
    end
  end

  describe "options that only allow limited values" do
    [[:preserve, ["always", "never", "on-failure"]]].each do |option, values|
      values.each do |value|
        it "can create a parser that accepts \"--#{option} #{value}\"" do
          subject = described_class.new
          expect(subject.parse!(%W[build --#{option} #{value} project platform]))
            .to include(option => value.to_sym)
        end
      end
    end
    [[:preserve, ["bad-argument"]]].each do |option, values|
      values.each do |value|
        it "rejects the bad argument \"--#{option} #{value}\"" do
          subject = described_class.new
          expect{subject.parse!(%W[build --#{option} #{value} project platform])}
            .to raise_error(Vanagon::InvalidArgument)
        end
      end
    end
    it "preserve defaults to :on-failure" do
      subject = described_class.new
      expect(subject.parse!([])).to include(:preserve => :'on-failure')
    end
  end


  describe "options that take a value" do
    [:workdir, :configdir, :engine].each do |option|
      it "can create an option parser that accepts the #{option} option" do
        subject = described_class.new
        expect(subject.parse!(%W[build --#{option} hello project platform]))
          .to include(option => "hello")
      end
    end

    describe "short options" do
      [["w", :workdir], ["c", :configdir], ["e", :engine]].each do |short, long|
        it "maps the short option #{short} to #{long}" do
          subject = described_class.new
          expect(subject.parse!(%W[build -#{short} hello project platform]))
            .to include(long => "hello")
        end
      end
    end
  end
end
