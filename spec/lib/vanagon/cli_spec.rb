require 'vanagon/cli'

##
## Ignore the CLI calling 'exit'
##
RSpec.configure do |rspec|
  rspec.around do |ex|
    begin
      ex.run
    rescue SystemExit => e
      puts "Got SystemExit: #{e.inspect}. Ignoring"
    end
  end
end

describe Vanagon::CLI do
  context "with options that don't take a value" do
    %i[skipcheck verbose].each do |flag|
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
          expect { subject.parse(%W[build --#{option} #{value} project platform]) }
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
    %i[workdir configdir engine].each do |option|
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
  let(:cli) { described_class.new }

  describe "#output" do
    let (:list) { ['a', 'b', 'c'] }

    it "returns an array if space is false" do
      expect(cli.output(list, false)).to eq(list)
    end

    it "returns space separated if space is true" do
      expect(cli.output(list, true)).to eq('a b c')
    end
  end

  describe "#run" do
    let(:defaults) { ['def1', 'def2', 'def3'] }
    let(:projects) { ['foo', 'bar', 'baz'] }
    let(:platforms) { ['1', '2', '3'] }
    let(:output_both) do
      "- Projects
bar
baz
foo

- Platforms
1
2
3
"
    end

    context "with standard config path" do
      before do
        allow(Dir).to receive(:exist?)
          .with(File.join(Dir.pwd, 'configs', 'platforms'))
          .and_return(true)
        allow(Dir).to receive(:exist?)
          .with(File.join(Dir.pwd, 'configs', 'projects'))
          .and_return(true)
        allow(Dir).to receive(:children)
          .with(File.join(Dir.pwd, 'lib', 'vanagon', 'cli', '..', 'platform', 'defaults'))
          .and_return(defaults)
        allow(Dir).to receive(:children)
          .with(File.join(Dir.pwd, 'configs', 'projects'))
          .and_return(projects)
        allow(Dir).to receive(:children)
          .with(File.join(Dir.pwd, 'configs', 'platforms'))
          .and_return(platforms)
      end

      let(:options_empty) do
        {
          configdir: "#{Dir.pwd}/configs",
          defaults: false,
          platforms: false,
          projects: false,
          use_spaces: false
        }
      end
      let(:options_space_only) do
        {
          configdir: "#{Dir.pwd}/configs",
          defaults: false,
          platforms: false,
          projects: false,
          use_spaces: true
        }
      end
      let(:output_both_space) do
        "- Projects
bar baz foo

- Platforms
1 2 3
"
      end

      it "outputs projects and platforms with no options passed" do
        expect do
          cli.run(options_empty)
        end.to output(output_both).to_stdout
      end


      it "outputs projects and platforms space separated" do
        expect do
          cli.run(options_space_only)
        end.to output(output_both_space).to_stdout
      end
    end

    context "with --platforms flag" do
      let(:options_platforms_only) do
        {
          configdir: "#{Dir.pwd}/configs",
          defaults: false,
          platforms: true,
          projects: false,
          use_spaces: false
        }
      end
      let(:output_platforms) { "1\n2\n3\n" }

      it "outputs only platforms when platforms is passed" do
        expect { cli.run(options_platforms_only) }.to output(output_platforms).to_stdout
      end
    end

    context "with --projects flag" do
      let(:options_projects_only) do
        {
          configdir: "#{Dir.pwd}/configs",
          defaults: false,
          platforms: false,
          projects: true,
          use_spaces: false
        }
      end
      let(:output_projects) { "bar\nbaz\nfoo\n" }

      it "outputs only projects when projects is passed" do
        expect { cli.run(options_projects_only) }.to output(output_projects).to_stdout
      end
    end

    context "with a configdir specified" do
      let(:options_configdir) do
        {
          configdir: '/configs',
          defaults: false,
          platforms: false,
          projects: false,
          use_spaces: false
        }
      end

      it "successfully takes the configs directory" do
        allow(Dir).to receive(:exist?).with('/configs/platforms')
          .and_return(true)
        allow(Dir).to receive(:exist?).with('/configs/projects')
          .and_return(true)
        allow(Dir).to receive(:children)
          .with(File.join(Dir.pwd, 'lib', 'vanagon', 'cli', '..', 'platform', 'defaults'))
          .and_return(defaults)
        allow(Dir).to receive(:children).with('/configs/projects')
          .and_return(projects)
        allow(Dir).to receive(:children).with('/configs/platforms')
          .and_return(platforms)
        expect { cli.run(options_configdir) }.to output(output_both).to_stdout
      end
    end

    context "with defaults" do
      let(:options_default_platforms) do
        {
          configdir: "#{Dir.pwd}/configs",
          defaults: true,
          platforms: false,
          projects: false,
          use_spaces: false
        }
      end
      let(:output_defaults) do
        "- Defaults
def1
def2
def3
"
      end

      it "lists the vanagon defaults" do
        allow(Dir).to receive(:exist?)
          .with(File.join(Dir.pwd, 'configs', 'platforms'))
          .and_return(true)
        allow(Dir).to receive(:exist?)
          .with(File.join(Dir.pwd, 'configs', 'projects'))
          .and_return(true)
        allow(Dir).to receive(:children)
          .with(File.join(Dir.pwd, 'lib', 'vanagon', 'cli', '..', 'platform', 'defaults'))
          .and_return(defaults)
        allow(Dir).to receive(:children)
          .with(File.join(Dir.pwd, 'configs', 'projects'))
          .and_return(projects)
        allow(Dir).to receive(:children)
          .with(File.join(Dir.pwd, 'configs', 'platforms'))
          .and_return(platforms)
        expect { cli.run(options_default_platforms) }.to output(output_defaults).to_stdout
      end
    end
  end
end
