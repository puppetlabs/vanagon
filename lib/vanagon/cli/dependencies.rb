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

        temp_dir = Dir.mktmpdir
        failures = []

        projects.each do |project|
          platforms.each do |platform|
            begin
              artifact = Vanagon::Driver.new(platform, project, options)
              artifact.dependencies(temp_dir)
            rescue => e
              failures.push("#{project}, #{platform}: #{e}")
            end
          end
        end

        if !failures.empty?
          VanagonLogger.info "Failed to generate dependencies for the following:"
          failures.each do |failure|
            VanagonLogger.info failure
          end
        end

        VanagonLogger.info "Dependency files located at: #{temp_dir}"
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
