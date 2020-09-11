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

    def parse!(argv)
      parsed_options = parse_options(argv)

      @sub_command = parsed_options['<command>']
      sub_argv = parsed_options['<args>']

      case @sub_command
      when 'build'
        raw_options = Vanagon::CLI::Build.parse(sub_argv)
        @options = options_translate(raw_options)
        options_validate
      when 'sign'
        @options = Vanagon::CLI::Sign.parse(sub_argv)
      when 'ship'
        @options = Vanagon::CLI::Ship.parse(sub_argv)
      when 'version'
        puts "Vanagon version #{::VANAGON_VERSION}"
        exit 0
      when 'help'
        puts DOCUMENTATION
        exit 0
      else
        warn "vanagon: Error: unknown command: \"#{@sub_command}\"\n\n#{DOCUMENTATION}"
        exit 1
      end

      return @options
    end

    def run
      case @sub_command
      when 'build'
        project = @options[:project_name]
        platform_list = @options[:platforms].split(',')
        target_list = []
        unless @options[:targets].nil? || @options[:targets].empty?
          target_list = @options[:targets].split(',')
        end

        platform_list.zip(target_list).each do |pair|
          platform, target = pair
          artifact = Vanagon::Driver.new(platform, project, @options.merge({ 'target' => target }))
          artifact.run
        end
      when 'sign'
        ENV['PROJECT_ROOT'] = Dir.pwd
        if Dir['output/**/*'].select { |entry| File.file?(entry) }.empty?
          warn 'vanagon: Error: No packages to sign in the "output" directory. Maybe build some first?'
          exit 1
        end

        require 'packaging'
        Pkg::Util::RakeUtils.load_packaging_tasks
        Pkg::Util::RakeUtils.invoke_task('pl:jenkins:sign_all', 'output')
      when 'ship'
        ENV['PROJECT_ROOT'] = Dir.pwd

        artifactory_warning = <<-DOC
          Unable to ship packages to artifactory. Please make sure you are pointing to a
          recent version of packaging in your Gemfile. Please also make sure you include
          the artifactory gem in your Gemfile.

          Examples:
            gem 'packaging', :github => 'puppetlabs/packaging', branch: '1.0.x'
            gem 'artifactory'
        DOC

        if Dir['output/**/*'].select { |entry| File.file?(entry) }.empty?
          warn 'vanagon: Error: No packages to ship in the "output" directory. Maybe build some first?'
          exit 1
        end

        require 'packaging'
        Pkg::Util::RakeUtils.load_packaging_tasks
        Pkg::Util::RakeUtils.invoke_task('pl:jenkins:ship', 'artifacts', 'output')
        begin
          Pkg::Util::RakeUtils.invoke_task('pl:jenkins:ship_to_artifactory', 'output')
        rescue LoadError
          warn artifactory_warning
        rescue StandardError
          warn artifactory_warning
        end
      end
    end

    # Do validation of options
    def options_validate
      # Handle --preserve option checking
      valid_preserves = %w[always never on-failure]
      unless valid_preserves.include? @options[:preserve]
        raise InvalidArgument, "--preserve option can only be one of: " +
                               valid_preserves.join(', ')
      end
      @options[:preserve] = @options[:preserve].to_sym
    end

    # Provide a translation from parsed docopt options to older optparse options
    def options_translate(docopt_options)
      translations = {
        '--verbose' => :verbose,
        '--workdir' => :workdir,
        '--remote-workdir' => :"remote-workdir",
        '--configdir' => :configdir,
        '--engine' => :engine,
        '--skipcheck' => :skipcheck,
        '--preserve' => :preserve,
        '--only-build' => :only_build,
        '<project-name>' => :project_name,
        '<platforms>' => :platforms,
        '<targets>' => :targets
      }
      return docopt_options.map { |k,v| [translations[k], v] }.to_h
    end

    private

    def parse_options(argv)
      Docopt.docopt(DOCUMENTATION, {
                      argv: argv,
                      version: ::VANAGON_VERSION,
                      options_first: true
                    })
    rescue Docopt::Exit => e
      puts e.message
      exit 1
    end
  end
end
