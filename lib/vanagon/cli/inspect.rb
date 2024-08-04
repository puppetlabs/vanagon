require 'docopt'
require 'json'
require 'vanagon/logger'

class Vanagon
  class CLI
    class Inspect < Vanagon::CLI
      DOCUMENTATION = <<~DOCOPT.freeze
        Usage:
        inspect [options] <project-name> <platforms>

        Options:
          -h, --help                       Display help
          -c, --configdir DIRECTORY        Configuration directory [default: #{Dir.pwd}/configs]
          -e, --engine ENGINE              Custom engine to use [default: always_be_scheduling]

          -p, --preserve [RULE]            Rule for VM preservation: never, on-failure, always
                                             [Default: on-failure]
          -w, --workdir DIRECTORY          Working directory on the local host
          -v, --verbose                    Only here for backwards compatibility. Does nothing.

        Engines:
          always_be_scheduling: default engine using Puppet's ABS infrastructure
          docker: a docker container on the local host
          ec2: an Amazon EC2 instance
          hardware: a dedicated hardware device
          local: the local machine, cannot be used with a target
          pooler: [deprecated] Puppet's vmpooler
      DOCOPT

      def parse(argv)
        Docopt.docopt(DOCUMENTATION, { argv: argv })
      rescue Docopt::Exit => e
        VanagonLogger.error e.message
        exit 1
      end

      def run(options)
        platforms = options[:platforms].split(',')
        project = options[:project_name]

        platforms.each do |platform|
          driver = Vanagon::Driver.new(platform, project, options)
          components = driver.project.components.map(&:to_hash)
          VanagonLogger.warn JSON.pretty_generate(components)
        end
      end

      def options_translate(docopt_options)
        translations = {
          '--verbose' => :verbose,
          '--workdir' => :workdir,
          '--configdir' => :configdir,
          '--engine' => :engine,
          '--preserve' => :preserve,
          '<project-name>' => :project_name,
          '<platforms>' => :platforms
        }
        return docopt_options.transform_keys { |k| translations[k] }
      end

      def options_validate(options)
        # Handle --preserve option checking
        valid_preserves = %w[always never on-failure]
        unless valid_preserves.include? options[:preserve]
          raise InvalidArgument, "--preserve option can only be one of: #{valid_preserves.join(', ')}"
        end
        options[:preserve] = options[:preserve].to_sym
        return options
      end
    end
  end
end
