require 'docopt'
require 'vanagon/logger'

class Vanagon
  class CLI
    class List < Vanagon::CLI
      DOCUMENTATION = <<~DOCOPT.freeze
        Usage:
          list [options]

        Options:
          -h, --help                       Display help
          -c, --configdir DIRECTORY        Configuration directory [default: #{Dir.pwd}/configs]
          -d, --defaults                   Display the list of default platforms
          -l, --platforms                  Display a list of platforms
          -r, --projects                   Display a list of projects
          -s, --use-spaces                 Displays the list as space separated
      DOCOPT

      def parse(argv)
        Docopt.docopt(DOCUMENTATION, { argv: argv })
      rescue Docopt::Exit => e
        VanagonLogger.error e.message
        exit 1
      end

      def output(list, use_spaces)
        return list.join(' ') if use_spaces
        return list
      end

      def run(options) # rubocop:disable Metrics/AbcSize
        if Dir.exist?(File.join(options[:configdir], 'platforms')) == false ||
           Dir.exist?(File.join(options[:configdir], 'projects')) == false

          VanagonLogger.error "Path to #{File.join(options[:configdir], 'platforms')} or #{File.join(options[:configdir], 'projects')} not found."
          exit 1
        end

        default_list = Dir.children(File.join(File.dirname(__FILE__), '..', 'platform', 'defaults')).map do |platform|
          File.basename(platform, File.extname(platform))
        end.sort

        platform_list = Dir.children(File.join(options[:configdir], 'platforms')).map do |platform|
          File.basename(platform, File.extname(platform))
        end.sort

        project_list = Dir.children(File.join(options[:configdir], 'projects')).map do |project|
          File.basename(project, File.extname(project))
        end.sort

        if options[:defaults]
          puts "- Defaults", output(default_list, options[:use_spaces])
          return
        end

        if options[:projects] == options[:platforms]
          puts "- Projects", output(project_list, options[:use_spaces]), "\n", "- Platforms", output(platform_list, options[:use_spaces])
          return
        end

        if options[:projects]
          puts output(project_list, options[:use_spaces])
          return
        end

        if options[:platforms]
          puts output(platform_list, options[:use_spaces])
          return
        end
      end

      def options_translate(docopt_options)
        translations = {
          '--configdir' => :configdir,
          '--defaults' => :defaults,
          '--platforms' => :platforms,
          '--projects' => :projects,
          '--use-spaces' => :use_spaces,
        }
        return docopt_options.map { |k, v| [translations[k], v] }.to_h
      end
    end
  end
end
