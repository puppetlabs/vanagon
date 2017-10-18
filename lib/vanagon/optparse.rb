require 'optparse'

class Vanagon
  class OptParse
    def initialize(banner, symbols = []) # rubocop:disable Metrics/AbcSize
      ## symbols array kept for backward compatibility but ignored

      @options = Hash.new
      @options[:preserve] = :'on-failure'

      @option_parser = OptionParser.new do |opts| # rubocop:disable Metrics/BlockLength
        opts.banner = banner
        opts.separator ""
        opts.separator "Options:"

        opts.on("-h",
                "--help",
                "Display help") do
          $stdout.puts opts
          exit 1
        end

        opts.on("-v",
                "--verbose",
                "Verbose output (does nothing)") do |verbose|
          @options[:verbose] = verbose
        end

        opts.on("-w DIRECTORY",
                "--workdir DIRECTORY",
                "Working directory on the local host (defaults to calling mktemp)") do |workdir|
          @options[:workdir] = workdir
        end

        opts.on("-r DIRECTORY",
                "--remote-workdir DIRECTORY",
                "Working directory on the remote host (defaults to calling mktemp)") do |remote|
          @options[:"remote-workdir"] = remote
        end

        opts.on("-c DIRECTORY",
                "--configdir DIRECTORY",
                "Configuration directory (defaults to $CWD/configs)") do |configuration_directory|
          @options[:configdir] = configuration_directory
        end

        opts.on("-t HOST",
                "--target HOST",
                "Name of target machine for build and packaging (defaults to requesting from the pooler)") do |target|
          @options[:target] = target
        end

        opts.on("-e ENGINE",
                "--engine ENGINE",
                "Custom engine to use [base, local, docker, pooler] (defaults to \"pooler\")") do |engine|
          @options[:engine] = engine
        end

        opts.on("--skipcheck",
                "Skip the \"check\" stage when building components") do |skipcheck|
          @options[:skipcheck] = skipcheck
        end

        opts.on("-p [RULE]",
                "--preserve [RULE]",
                ["never", "on-failure", "always"],
                "Rule for VM preservation. [never, on-failure, always]") do |rule|
          if rule.nil?
            @options[:preserve] = :always
          else
            @options[:preserve] = rule.to_sym
          end
        end

        opts.on("--only-build COMPONENT,COMPONENT,...",
                Array,
                "Only build listed COMPONENTs") do |components|
          @options[:only_build] = components
        end
      end
    end

    def parse!(args)
      @option_parser.parse!(args)
      @options
    end

    def to_s
      @optparse.to_s
    end
  end
end
