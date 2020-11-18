require 'docopt'

class Vanagon
  class CLI
    class List < Vanagon::CLI
      DOCUMENTATION = <<~DOCOPT.freeze
        Usage:
          list [--help]

        Options:
          -h, --help                       Display help
          -r, --projects                   Display a list of projects
          -l, --platforms                  Display a list of platforms
      DOCOPT

      def parse(argv)
        Docopt.docopt(DOCUMENTATION, { argv: argv })
      rescue Docopt::Exit => e
        puts e.message
        exit 1
      end

      def run(_)
        puts "hi"
        # ENV['PROJECT_ROOT'] = Dir.pwd

        # artifactory_warning = <<-DOC
        #   Unable to ship packages to artifactory. Please make sure you are pointing to a
        #   recent version of packaging in your Gemfile. Please also make sure you include
        #   the artifactory gem in your Gemfile.

        #   Examples:
        #     gem 'packaging', :github => 'puppetlabs/packaging', branch: '1.0.x'
        #     gem 'artifactory'
        # DOC

        # if Dir['output/**/*'].select { |entry| File.file?(entry) }.empty?
        #   warn 'vanagon: Error: No packages to ship in the "output" directory. Maybe build some first?'
        #   exit 1
        # end

        # require 'packaging'
        # Pkg::Util::RakeUtils.load_packaging_tasks
        # Pkg::Util::RakeUtils.invoke_task('pl:jenkins:ship', 'artifacts', 'output')
        # begin
        #   Pkg::Util::RakeUtils.invoke_task('pl:jenkins:ship_to_artifactory', 'output')
        # rescue LoadError
        #   warn artifactory_warning
        # rescue StandardError
        #   warn artifactory_warning
        # end
      end
    end
  end
end
