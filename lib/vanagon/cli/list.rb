require 'docopt'

class Vanagon
  class CLI
    class List < Vanagon::CLI
      DOCUMENTATION = <<~DOCOPT.freeze
        Usage:
          list [options]

        Options:
          -h, --help                       Display help
          -r, --projects                   Display a list of projects
          -l, --platforms                  Display a list of platforms
          -s, --space                      Displays the list as space separated
      DOCOPT

      def parse(argv)
        Docopt.docopt(DOCUMENTATION, { argv: argv })
      rescue Docopt::Exit => e
        puts e.message
        exit 1
      end

      def run(options)
        platform_list = Dir.children('configs/platforms').map do |platform|
          File.basename(platform, File.extname(platform))
        end

        project_list = Dir.children('configs/projects').map do |project|
          File.basename(project, File.extname(project))
        end
        
        if options[:projects] == options[:platforms]
          puts "- Projects", project_list, "\n", "- Platforms", platform_list, "\n"
        elsif options[:projects]
          puts "- Projects", project_list
        elsif options[:platforms]
          puts "- Platforms", platform_list
        end
        
      end

      def options_translate(docopt_options)
        translations = {
          '--projects' => :projects,
          '--platforms' => :platforms,
          '--space' => :space,
        }
        return docopt_options.map { |k, v| [translations[k], v] }.to_h
      end
    end
  end
end
