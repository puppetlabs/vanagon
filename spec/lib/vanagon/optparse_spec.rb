require 'vanagon/optparse'

describe Vanagon::OptParse do

  describe "options that don't take a value" do
    [:skipcheck, :verbose].each do |flag|
      it "can create an option parser that accepts the #{flag} flag" do
        subject = described_class.new("test", [flag])
        expect(subject.parse!(["--#{flag}"])).to have_key(flag)
      end
    end

    describe "short options" do
      [["v", :verbose]].each do |short, long|
        it "maps the short option #{short} to #{long}" do
          subject = described_class.new("test", [long])
          expect(subject.parse!(["-#{short}"])).to include(long => true)
        end
      end
    end
  end

  describe "options that only allow limited values" do
    [[:preserve, ["always", "never", "on-failure"]]].each do |option, values|
      values.each do |value|
        it "can create a parser that accepts \"--#{option} #{value}\"" do
          subject = described_class.new("test", [option, value])
          expect(subject.parse!(["--#{option}", value])).to eq(option => value.to_sym)
        end
      end
    end
    [[:preserve, ["bad-argument"]]].each do |option, values|
      values.each do |value|
        it "rejects the bad argument \"--#{option} #{value}\"" do
          subject = described_class.new("test", [option, value])
          expect{subject.parse!(["--#{option}", value])}.to raise_error(OptionParser::InvalidArgument)
        end
      end
    end
    it "preserve defaults to :on-failure" do
      subject = described_class.new("test")
      expect(subject.parse!([])).to include(:preserve => :'on-failure')
    end
  end


  describe "options that take a value" do
    [:workdir, :configdir, :target, :engine].each do |option|
      it "can create an option parser that accepts the #{option} option" do
        subject = described_class.new("test", [option])
        expect(subject.parse!(["--#{option}", "hello"])).to include(option => "hello")
      end
    end

    describe "short options" do
      [["w", :workdir], ["c", :configdir], ["t", :target], ["e", :engine]].each do |short, long|
        it "maps the short option #{short} to #{long}" do
          subject = described_class.new("test", [long])
          expect(subject.parse!(["-#{short}", "hello"])).to include(long => "hello")
        end
      end
    end
  end
end
