require 'docopt'
require 'json'

require 'vanagon/extensions/ostruct/json'
require 'vanagon/extensions/set/json'
require 'vanagon/extensions/hashable'

require 'vanagon/cli/build'
require 'vanagon/cli/build_host_info'
require 'vanagon/cli/build_requirements'
require 'vanagon/cli/inspect'
require 'vanagon/cli/list'
require 'vanagon/cli/render'
require 'vanagon/cli/ship'
require 'vanagon/cli/sign'


class Vanagon
  class InvalidArgument < StandardError
  end

  class CLI
    DOCUMENTATION = <<~DOCOPT.freeze
      *******TEST VERSION******
      Usage:
          vanagon <command> [<args>]...

      Commands are:
          build               build a package given a project and platform
          build_host_info     print information about build hosts
          build_requirements  print external packages required to build project
          inspect             a build dry-run, printing lots of information about the build
          list                Shows a list of available projects and platforms
          render              create local versions of packaging artifacts for project
          sign                sign a package
          ship                upload a package to a distribution server
          help                print this help
    DOCOPT

    def parse(argv) # rubocop:disable Metrics/AbcSize
      parsed_options = parse_options(argv)
      sub_command = parsed_options['<command>']
      sub_argv = parsed_options['<args>']

      case sub_command
      when 'build'
        @sub_parser = Vanagon::CLI::Build.new
      when 'build_host_info'
        @sub_parser = Vanagon::CLI::BuildHostInfo.new
      when 'build_requirements'
        @sub_parser = Vanagon::CLI::BuildRequirements.new
      when 'inspect'
        @sub_parser = Vanagon::CLI::Inspect.new
      when 'render'
        @sub_parser = Vanagon::CLI::Render.new
      when 'list'
        @sub_parser = Vanagon::CLI::List.new
      when 'sign'
        @sub_parser = Vanagon::CLI::Sign.new
      when 'ship'
        @sub_parser = Vanagon::CLI::Ship.new
      when 'help'
        puts DOCUMENTATION
        exit 0
      else
        warn "vanagon: Error: unknown command: \"#{sub_command}\"\n\n#{DOCUMENTATION}"
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
      Docopt.docopt(DOCUMENTATION, { argv: argv, options_first: true })
    rescue Docopt::Exit => e
      puts e.message
      exit 1
    end
  end
end
