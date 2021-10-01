require 'docopt'
require 'json'
require 'vanagon/logger'

class Vanagon
  class CLI
    class Lock < Vanagon::CLI
      DOCUMENTATION = <<~DOCOPT.freeze
        Usage:
        lock [options] <project-name> <platforms>

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
        if Dir.exist?(File.join(options[:configdir], 'platforms')) == false ||
           Dir.exist?(File.join(options[:configdir], 'projects')) == false

          VanagonLogger.error "Path to #{File.join(options[:configdir], 'platforms')} or #{File.join(options[:configdir], 'projects')} not found."
          exit 1
        end

        projects = [options[:project_name]]
        if options[:project_name] == 'all'
          projects = Dir.children(File.join(options[:configdir], 'projects')).map do |project|
            File.basename(project, File.extname(project))
          end
        end

        platforms = options[:platforms].split(',')
        if options[:platforms] == 'all'
          platforms = Dir.children(File.join(options[:configdir], 'platforms')).map do |platform|
            File.basename(platform, File.extname(platform))
          end
        end

        projects.each do |project|
          platforms.each do |platform|
            artifact = Vanagon::Driver.new(platform, project, options)
            artifact.lock
          end
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
