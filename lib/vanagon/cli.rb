require 'docopt'

require 'vanagon/cli/build'
require 'vanagon/cli/sign'
require 'vanagon/cli/ship'

class Vanagon
  class InvalidArgument < StandardError
  end

  class CLI
    DOCUMENTATION = <<~DOCOPT
      Usage:
          vanagon <command> [<args>]...

      Commands are:
          build    build a package given a project and platform
          sign     sign a package
          ship     upload a package to a distribution server
          help     print this help
          version  print vanagon version
    DOCOPT

    def parse(argv)
      parsed_options = parse_options(argv)
      sub_command = parsed_options['<command>']
      sub_argv = parsed_options['<args>']

      case sub_command
      when 'build'
        @sub_parser = Vanagon::CLI::Build.new
      when 'sign'
        @sub_parser = Vanagon::CLI::Sign.new
      when 'ship'
        @sub_parser = Vanagon::CLI::Ship.new
      when 'help'
        puts DOCUMENTATION
        exit 0
      else
        warn "vanagon: Error: unknown command: \"#{@sub_command}\"\n\n#{DOCUMENTATION}"
        exit 1
      end

      raw_options = @sub_parser.parse(sub_argv)
      options = @sub_parser.options_translate(raw_options)
      @sub_parser.options_validate(options)
      return options
    end

    def run(options)
      @sub_parser.run(options)
    end

    # Do validation of options
    def options_validate(options)
      options
    end

    # Provide a translation from parsed docopt options to older optparse options
    def options_translate(docopt_options)
      docopt_options
    end

    private

    def parse_options(argv)
      Docopt.docopt(DOCUMENTATION, {
                      argv: argv,
                      options_first: true
                    })
    rescue Docopt::Exit => e
      puts e.message
      exit 1
    end
  end
end
