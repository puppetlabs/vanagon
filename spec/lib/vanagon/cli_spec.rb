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
        expect(subject.parse(%W[build --#{flag} project platform])).to have_key(flag)
      end
    end

    describe "short options" do
      [["v", :verbose]].each do |short, long|
        it "maps the short option #{short} to #{long}" do
          subject = described_class.new
          expect(subject.parse(%W[build -#{short} project platform])).to include(long => true)
        end
      end
    end
  end

  describe "options that only allow limited values" do
    [[:preserve, ["always", "never", "on-failure"]]].each do |option, values|
      values.each do |value|
        it "can create a parser that accepts \"--#{option} #{value}\"" do
          subject = described_class.new
          expect(subject.parse(%W[build --#{option} #{value} project platform]))
            .to include(option => value.to_sym)
        end
      end
    end
    [[:preserve, ["bad-argument"]]].each do |option, values|
      values.each do |value|
        it "rejects the bad argument \"--#{option} #{value}\"" do
          subject = described_class.new
          expect{subject.parse(%W[build --#{option} #{value} project platform])}
            .to raise_error(Vanagon::InvalidArgument)
        end
      end
    end
    it "preserve defaults to :on-failure" do
      subject = described_class.new
      expect(subject.parse([])).to include(:preserve => :'on-failure')
    end
  end


  describe "options that take a value" do
    [:workdir, :configdir, :engine].each do |option|
      it "can create an option parser that accepts the #{option} option" do
        subject = described_class.new
        expect(subject.parse(%W[build --#{option} hello project platform]))
          .to include(option => "hello")
      end
    end

    describe "short options" do
      [["w", :workdir], ["c", :configdir], ["e", :engine]].each do |short, long|
        it "maps the short option #{short} to #{long}" do
          subject = described_class.new
          expect(subject.parse(%W[build -#{short} hello project platform]))
            .to include(long => "hello")
        end
      end
    end
  end
end

describe Vanagon::CLI::List do 
  let(:cli) { Vanagon::CLI::List.new }
  
  describe "#output" do 
      let(:list) { ['a', 'b', 'c']}
      it "returns an array if space is false" do 
          expect(cli.output(list, false)).to eq(list)
      end 
      it "returns space separated if space is true" do 
          expect(cli.output(list, true)).to eq('a b c')
      end 
  end

  describe "#run" do 
    let(:projects){ ['foo', 'bar', 'baz'] }
    let(:platforms){ ['1', '2', '3'] }
    let(:output_both){
"- Projects
foo
bar
baz

- Platforms
1
2
3
"
}
    context "specs with standard config path" do
      before(:each) do
        expect(Dir).to receive(:children)
          .with("#{File.join(Dir.pwd, 'configs', 'projects')}")
          .and_return(projects)
        expect(Dir).to receive(:children)
          .with("#{File.join(Dir.pwd, 'configs', 'platforms')}")
          .and_return(platforms)
      end
      let(:options_empty) { {
        nil=>false, 
        :configdir=>false, 
        :platforms=>false, 
        :projects=>false, 
        :space=>false
      } }
      let(:options_platforms_only) { {
        nil=>false, 
        :configdir=>false, 
        :platforms=>true, 
        :projects=>false, 
        :space=>false
      } }
      let(:options_projects_only) { {
        nil=>false, 
        :configdir=>false, 
        :platforms=>false, 
        :projects=>true, 
        :space=>false
      } }
      let(:options_space_only) { {
        nil=>false, 
        :configdir=>false, 
        :platforms=>false, 
        :projects=>false, 
        :space=>true
      } }

      it "outputs projects and platforms with no options passed" do 
        expect do
          cli.run(options_empty)
        end.to output(output_both).to_stdout
      end
      
      let(:output_both_space){
"- Projects
foo bar baz

- Platforms
1 2 3
"
  }
      it "outputs projects and platforms space separated" do 
        expect do
          cli.run(options_space_only)
        end.to output(output_both_space).to_stdout
      end

      let(:output_platforms){
"- Platforms
1
2
3
"
}
      it "outputs only platforms when platforms is passed" do 
        expect do
          cli.run(options_platforms_only)
        end.to output(output_platforms).to_stdout
      end

      let(:output_projects){
"- Projects
foo
bar
baz
"
}
      it "outputs only projects when projects is passed" do 
        expect do
          cli.run(options_projects_only)
        end.to output(output_projects).to_stdout
      end
    end

    context "spec with a configdir specified" do
      let(:options_configdir) { {
        nil=>false, 
        :configdir=> '/configs', 
        :platforms=>false, 
        :projects=>false, 
        :space=>false} }
      it "it successfully takes the configs directory" do 
        expect(Dir).to receive(:children).with('/configs' + '/projects')
          .and_return(projects)
        expect(Dir).to receive(:children).with('/configs' + '/platforms')
          .and_return(platforms)
        expect do
          cli.run(options_configdir)
        end.to output(output_both).to_stdout
      end
    end
  end
end

      

