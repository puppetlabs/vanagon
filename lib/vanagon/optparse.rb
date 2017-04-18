require 'optparse'

class Vanagon
  class OptParse
    FLAGS = {
        :workdir => ['-w DIR', '--workdir DIR', "Working directory where build source should be put (defaults to a tmpdir)"],
        :"remote-workdir" => ['-r DIR', '--remote-workdir DIR', "Working directory where build source should be put on the remote host (defaults to a tmpdir)"],
        :configdir => ['-c', '--configdir DIR', 'Configs dir (defaults to $pwd/configs)'],
        :target => ['-t HOST', '--target HOST', 'Configure a target machine for build and packaging (defaults to grabbing one from the pooler)'],
        :engine => ['-e ENGINE', '--engine ENGINE', "A custom engine to use (defaults to the pooler) [base, local, docker, pooler currently supported]"],
        :skipcheck => ['--skipcheck', 'Skip the `check` stage when building components'],
        :preserve => ['-p', '--preserve', 'Whether to tear down the VM on success or not (defaults to false)'],
        :verbose => ['-v', '--verbose', 'Verbose output (does nothing)'],
        :only_build => ["--only-build COMPONENT,COMPONENT,...", Array, 'Only build this array of components']
      }.freeze

    def initialize(banner, options = [])
      @options = Hash[options.map { |v| [v, nil] }]
      @optparse = OptionParser.new do |opts|
        opts.banner = banner

        FLAGS.each_pair do |name, args|
          if @options.include?(name)
            opts.on(*args) do |value|
              @options[name] = value
            end
          end
        end

        opts.on('-h', '--help', 'Display help') do
          $stdout.puts opts
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
