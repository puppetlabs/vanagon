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
          -e, --engine ENGINE              Custom engine to use [base, local, docker, pooler] [default: pooler]
          -w, --workdir DIRECTORY          Working directory on the local host
          -v, --verbose                    Only here for backwards compatibility. Does nothing.
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
        return docopt_options.map { |k, v| [translations[k], v] }.to_h
      end
    end
  end
end
