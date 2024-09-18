require 'docopt'
require 'json'
require 'vanagon/logger'

class Vanagon
  class CLI
    class Render < Vanagon::CLI
      DOCUMENTATION = <<~DOCOPT.freeze
        Usage:
        render [options] <project-name> <platforms>

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
        target_list = []

        platforms.zip(target_list).each do |pair|
          platform, target = pair
          artifact = Vanagon::Driver.new(platform, project, options.merge({ :target => target }))
          artifact.render
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
        }
        return docopt_options.transform_keys { |k| translations[k] }
      end
    end
  end
end
