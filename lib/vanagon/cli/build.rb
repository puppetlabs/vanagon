require 'docopt'

class Vanagon
  class CLI
    class Build
      DOCUMENTATION = <<~DOCOPT
        Usage:
        build [options] <project-name> <platforms> [<targets>]

        Options:
          -h, --help                       Display help
          -c, --configdir DIRECTORY        Configuration directory [default: #{Dir.pwd}/configs]
          -e, --engine ENGINE              Custom engine to use [base, local, docker, pooler] [default: pooler]
          -o, --only-build COMPONENT,COMPONENT,...
                                           Only build listed COMPONENTs
          -p, --preserve [RULE]            Rule for VM preservation: never, on-failure, always
                                             [Default: always]
          -r, --remote-workdir DIRECTORY   Working directory on the remote host
          -s, --skipcheck                  Skip the "check" stage when building components
          -w, --workdir DIRECTORY          Working directory on the local host
          -v, --verbose                    Only here for backwards compatibility. Does nothing.
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
