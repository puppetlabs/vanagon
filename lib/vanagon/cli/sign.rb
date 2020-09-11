require 'docopt'

class Vanagon
  class CLI
    class Sign
      DOCUMENTATION = <<~DOCOPT
        Usage:
          sign [--help]

        Options:
          -h, --help                       Display help
      DOCOPT

      def self.parse(argv)
        Docopt.docopt(DOCUMENTATION, {
                        argv: argv,
                        version: VANAGON_VERSION,
                        options_first: true
                      })
      rescue Docopt::Exit => e
        puts e.message
        exit 1
      end
    end
  end
end
