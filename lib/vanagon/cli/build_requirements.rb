require 'docopt'
require 'json'
require 'vanagon/logger'

class Vanagon
  class CLI
    class BuildRequirements < Vanagon::CLI
      DOCUMENTATION = <<~DOCOPT.freeze
        Usage:
        build_requirements [options] <project-name> <platform>

        Options:
          -h, --help                       Display help
          -c, --configdir DIRECTORY        Configuration directory [default: #{Dir.pwd}/configs]
          -e, --engine ENGINE              Custom engine to use [default: always_be_scheduling]
          -w, --workdir DIRECTORY          Working directory on the local host
          -v, --verbose                    Only here for backwards compatibility. Does nothing.

        Engines:
          always_be_scheduling: default engine using Puppet's ABS infrastructure
          docker: a docker container on the local host
          ec2: an Amazon EC2 instance
          hardware: a dedicated hardware device
          local: the local machine, cannot be used with a target
          pooler: [deprecated] Puppet's vmpooler
      DOCOPT

      def parse(argv)
        Docopt.docopt(DOCUMENTATION, { argv: argv })
      rescue Docopt::Exit => e
        VanagonLogger.error e.message
        exit 1
      end

      def run(options) # rubocop:disable Metrics/AbcSize
        platform = options[:platform]
        project = options[:project_name]
        driver = Vanagon::Driver.new(platform, project)

        components = driver.project.components
        component_names = components.map(&:name)
        build_requirements = components.map do |component|
          component.build_requires.reject do |requirement|
            # only include external requirements: i.e. those that do not match
            # other components in the project
            component_names.include?(requirement)
          end
        end

        VanagonLogger.warn "**** External packages required to build #{project} on #{platform}: ***"
        VanagonLogger.warn JSON.pretty_generate(build_requirements.flatten.uniq.sort)
      end

      def options_translate(docopt_options)
        translations = {
          '--verbose' => :verbose,
          '--workdir' => :workdir,
          '--configdir' => :configdir,
          '--engine' => :engine,
          '<project-name>' => :project_name,
          '<platform>' => :platform,
        }
        return docopt_options.transform_keys { |k| translations[k] }
      end
    end
  end
end
