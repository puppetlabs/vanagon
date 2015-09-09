require 'optparse'

class Vanagon
  class OptParse
    def initialize(banner, options = [])
      @options = Hash[options.map { |v| [v, nil] }]
      @optparse = OptionParser.new do |opts|
        opts.banner = banner

        if @options.include?(:workdir)
          opts.on('-w DIR', '--workdir DIR', "Working directory where build source should be put (defaults to a tmpdir)") do |dir|
            @options[:workdir] = dir
          end
        end

        if @options.include?(:configdir)
          opts.on('-c', '--configdir DIR', 'Configs dir (defaults to $pwd/configs)') do |dir|
            @options[:configdir] = dir
          end
        end

        if @options.include?(:target)
          opts.on('-t HOST', '--target HOST', 'Configure a target machine for build and packaging (defaults to grabbing one from the pooler)') do |name|
            @options[:target] = name
          end
        end

        if @options.include?(:engine)
          opts.on('-e ENGINE', '--engine ENGINE', "A custom engine to use (defaults to the pooler) [base, local, docker, pooler currently supported]") do |engine|
            @options[:engine] = engine
          end
        end

        if @options.include?(:preserve)
          opts.on('-p', '--preserve', 'Whether to tear down the VM on success or not (defaults to false)') do |flag|
            @options[:preserve] = flag
          end
        end

        if @options.include?(:verbose)
          opts.on('-v', '--verbose', 'Verbose output (does nothing)') do |flag|
            @options[:verbose] = flag
          end
        end

        opts.on('-h', '--help', 'Display help') do
          puts opts
          exit 1
        end
      end
    end

    def parse!(args)
      @optparse.parse!(args)
      @options
    end

    def to_s
      @optparse.to_s
    end
  end
end
