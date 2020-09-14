require 'docopt'

class Vanagon
  class CLI
    class BuildHostInfo < Vanagon::CLI
      DOCUMENTATION = <<~DOCOPT.freeze
        Usage:
        build_host_info [options] <project-name> <platforms>

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
        puts e.message
        exit 1
      end

      def run(options)
        platforms = options[:platforms].split(',')
        project = options[:project_name]

        platforms.each do |platform|
          driver = Vanagon::Driver.new(platform, project, options)
          $stdout.puts JSON.generate(driver.build_host_info)
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
        return docopt_options.map { |k, v| [translations[k], v] }.to_h
      end
    end
  end
end
