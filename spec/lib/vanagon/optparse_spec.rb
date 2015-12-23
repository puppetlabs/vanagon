require 'vanagon/optparse'

describe Vanagon::OptParse do

  describe "options that don't take a value" do
    [:skipcheck, :preserve, :verbose].each do |flag|
      it "can create an option parser that accepts the #{flag} flag" do
        subject = described_class.new("test", [flag])
        expect(subject.parse!(["--#{flag}"])).to eq(flag => true)
      end
    end

    describe "short options" do
      [["p", :preserve], ["v", :verbose]].each do |short, long|
        it "maps the short option #{short} to #{long}" do
          subject = described_class.new("test", [long])
          expect(subject.parse!(["-#{short}"])).to eq(long => true)
        end
      end
    end
  end

  describe "options that take a value" do
    [:workdir, :configdir, :target, :engine].each do |option|
      it "can create an option parser that accepts the #{option} option" do
        subject = described_class.new("test", [option])
        expect(subject.parse!(["--#{option}", "hello"])).to eq(option => "hello")
      end
    end

    describe "short options" do
      [["w", :workdir], ["c", :configdir], ["t", :target], ["e", :engine]].each do |short, long|
        it "maps the short option #{short} to #{long}" do
          subject = described_class.new("test", [long])
          expect(subject.parse!(["-#{short}", "hello"])).to eq(long => "hello")
        end
      end
    end
  end
end
