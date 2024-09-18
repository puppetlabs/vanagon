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
        check_directories(options)

        default_list = topic_list(File.dirname(__FILE__), '..', 'platform', 'defaults')
        platform_list = topic_list(options[:configdir], 'platforms')
        project_list = topic_list(options[:configdir], 'projects')

        if options[:defaults]
          puts "- Defaults", output(default_list, options[:use_spaces])
          return
        end

        if options[:projects] == options[:platforms]
          puts "- Projects", output(project_list, options[:use_spaces]), "\n",
               "- Platforms", output(platform_list, options[:use_spaces])
          return
        end

        if options[:projects]
          puts "- Projects", output(project_list, options[:use_spaces])
          return
        end

        if options[:platforms]
          puts "- Platforms", output(platform_list, options[:use_spaces])
          return
        end
      end

      def check_directories(options)
        platforms_directory = File.join(options[:configdir], 'platforms')
        projects_directory = File.join(options[:configdir], 'projects')

        unless Dir.exist?(platforms_directory)
          VanagonLogger.error "Platforms directory \"#{platforms_directory}\" does not exist."
          exit 1
        end

        unless Dir.exist?(projects_directory)
          VanagonLogger.error "Projectss directory \"#{projects_directory}\" does not exist."
          exit 1
        end
      end

      def topic_list(*topic_path_items)
        Dir.children(File.join(topic_path_items)).map do |t|
          File.basename(t, File.extname(t))
        end.sort
      end

      def options_translate(docopt_options)
        translations = {
          '--configdir' => :configdir,
          '--defaults' => :defaults,
          '--platforms' => :platforms,
          '--projects' => :projects,
          '--use-spaces' => :use_spaces,
        }
        return docopt_options.transform_keys { |k| translations[k] }
      end
    end
  end
end
