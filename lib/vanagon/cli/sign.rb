require 'docopt'
require 'vanagon/logger'

class Vanagon
  class CLI
    class Sign < Vanagon::CLI
      DOCUMENTATION = <<~DOCOPT.freeze
        Usage:
          sign [--help]

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
        if Dir['output/**/*'].select { |entry| File.file?(entry) }.empty?
          VanagonLogger.error 'sign: Error: No packages to sign in the "output" directory. Maybe build some first?'
          exit 1
        end

        require 'packaging'
        Pkg::Util::Sign.sign_all('output')
      end
    end
  end
end
