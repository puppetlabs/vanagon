require 'docopt'
require 'vanagon/logger'

class Vanagon
  class CLI
    class Ship < Vanagon::CLI
      DOCUMENTATION = <<~DOCOPT.freeze
        Usage:
          ship [--help]

        Options:
          -h, --help                       Display help
      DOCOPT

      def parse(argv)
        Docopt.docopt(DOCUMENTATION, { argv: argv })
      rescue Docopt::Exit => e
        VanagonLogger.error e.message
        exit 1
      end

      def run(_)
        ENV['PROJECT_ROOT'] = Dir.pwd

        if Dir['output/**/*'].none? { |entry| File.file?(entry) }
          VanagonLogger.error 'vanagon: Error: No packages to ship in the "output" directory. Maybe build some first?'
          exit 1
        end

        require 'packaging'
        Pkg::Util::RakeUtils.load_packaging_tasks
        Pkg::Util::RakeUtils.invoke_task('pl:jenkins:ship', 'artifacts', 'output')
        Pkg::Util::RakeUtils.invoke_task('pl:jenkins:ship_to_artifactory', 'output')
      end
    end
  end
end
