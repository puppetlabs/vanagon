require 'docopt'
require 'json'
require 'vanagon/logger'

class Vanagon
  class CLI
    class Dependencies < Vanagon::CLI
      DOCUMENTATION = <<~DOCOPT.freeze
        Usage:
        dependencies [options] <project-name> <platforms>

        Options:
          -h, --help                       Display help
          -c, --configdir DIRECTORY        Configuration directory [default: #{Dir.pwd}/configs]
          -w, --workdir DIRECTORY          Working directory on the local host
          -v, --verbose                    Only here for backwards compatibility. Does nothing.

        Project-Name:
          May be a project name of a project from the configs/projects directory or 'all' to generate dependencies for all projects.
        Platforms:
          May be a platform name of a platform from the configs/platforms directory or 'all' to generate dependencies for all platforms.
      DOCOPT

      def parse(argv)
        Docopt.docopt(DOCUMENTATION, { argv: argv })
      rescue Docopt::Exit => e
        VanagonLogger.error e.message
        exit 1
      end

      def run(options) # rubocop:disable Metrics/AbcSize
        platforms_directory = File.join(options[:configdir], 'platforms')
        projects_directory = File.join(options[:configdir], 'projects')

        unless Dir.exist?(projects_directory) && Dir.exist?(platforms_directory)
          VanagonLogger.error "Path to #{platforms_directory} or #{projects_directory} not found."
          exit 1
        end

        projects = [options[:project_name]]
        if projects.include?('all')
          projects = Dir.children(projects_directory).map do |project|
            File.basename(project, File.extname(project))
          end
        end

        platforms = options[:platforms].split(',')
        if platforms.include?('all')
          platforms = Dir.children(platforms_directory).map do |platform|
            File.basename(platform, File.extname(platform))
          end
        end

        temporary_directory = Dir.mktmpdir
        failures = []

        projects.each do |project|
          platforms.each do |platform|
            begin
              artifact = Vanagon::Driver.new(platform, project, options)
              artifact.dependencies(temporary_directory)
            rescue RuntimeError => e
              failures.push("#{project}, #{platform}: #{e}")
            end
          end
        end

        unless failures.empty?
          VanagonLogger.info "Failed to generate dependencies for the following:"
          failures.each do |failure|
            VanagonLogger.info failure
          end
        end

        VanagonLogger.info "Dependency files located at: #{temporary_directory}"
      end

      def options_translate(docopt_options)
        translations = {
          '--verbose' => :verbose,
          '--workdir' => :workdir,
          '--configdir' => :configdir,
          '<project-name>' => :project_name,
          '<platforms>' => :platforms
        }
        return docopt_options.map { |k, v| [translations[k], v] }.to_h
      end
    end
  end
end