require 'docopt'
require 'vanagon/logger'

class Vanagon
  class CLI
    class BuildHostInfo < Vanagon::CLI
      DOCUMENTATION = <<~DOCOPT.freeze
        Usage:
        build_host_info [options] <project-name> <platforms>

        Options:
          -h, --help                       Display help
          -c, --configdir DIRECTORY        Configuration directory [default: #{Dir.pwd}/configs]
          -e, --engine ENGINE              Custom engine to use [default: always_be_scheduling]
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
          VanagonLogger.warn JSON.generate(driver.build_host_info)
        end
      end

      def options_translate(docopt_options)
        translations = {
          '--verbose' => :verbose,
          '--workdir' => :workdir,
          '--configdir' => :configdir,
          '--engine' => :engine,
          '<project-name>' => :project_name,
          '<platforms>' => :platforms,
          '<targets>' => :targets
        }
        return docopt_options.transform_keys { |k| translations[k] }
      end
    end
  end
end
