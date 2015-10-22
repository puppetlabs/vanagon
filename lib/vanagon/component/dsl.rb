require 'vanagon/component'
require 'ostruct'
require 'json'

class Vanagon
  class Component
    class DSL
      # Constructor for the DSL object
      #
      # @param name [String] name of the component
      # @param settings [Hash] settings to use in building the component
      # @param platform [Vanagon::Platform] platform to build the component for
      # @return [Vanagon::Component::DSL] A DSL object to describe the {Vanagon::Component}
      def initialize(name, settings, platform)
        @name = name
        @component = Vanagon::Component.new(@name, settings, platform)
      end

      # Primary way of interacting with the DSL
      #
      # @param name [String] name of the componennt
      # @param block [Proc] DSL definition of the component to call
      def component(name, &block)
        block.call(self, @component.settings, @component.platform)
      end

      # Accessor for the component.
      #
      # @return [Vanagon::Component] the component the DSL methods will be acting against
      def _component
        @component
      end

      # All purpose getter. This object, which is passed to the component block,
      # won't have easy access to the attributes of the @component, so we make a
      # getter for each attribute.
      #
      # We only magically handle get_ methods, any other methods just get the
      # standard method_missing treatment.
      #
      def method_missing(method, *args)
        attribute_match = method.to_s.match(/get_(.*)/)
        if attribute_match
          attribute = attribute_match.captures.first
        else
          super
        end

        @component.send(attribute)
      end

      # Set or add to the configure call for the component. The commands required to configure the component before building it.
      #
      # @param block [Proc] the command(s) required to configure the component
      def configure(&block)
        @component.configure << block.call
      end

      # Set or add to the build call for the component. The commands required to build the component before installing it.
      #
      # @param block [Proc] the command(s) required to build the component
      def build(&block)
        @component.build << block.call
      end

      # Set or add to the install call for the component. The commands required to install the component.
      #
      # @param block [Proc] the command(s) required to install the component
      def install(&block)
        @component.install << block.call
      end

      # Setup any specific environment required to configure, build or install the component
      #
      # @param block [Proc] the environment required to configure, build or install the component
      def environment(&block)
        @component.environment = block.call
      end

      # Add a patch to the list of patches to apply to the component's source after unpacking
      #
      # @param patch [String] Path to the patch that should be applied
      # @param strip [String, Integer] directory levels to skip in applying patch
      # @param fuzz [String, Integer] levels of context miss to ignore in applying patch
      def apply_patch(patch, strip: 1, fuzz: 0)
        @component.patches << OpenStruct.new('path' => patch, 'strip' => strip.to_s, 'fuzz' => fuzz.to_s)
      end

      # Loads and parses json from a file. Will treat the keys in the
      # json as methods to invoke on the component in question
      #
      # @param file [String] Path to the json file
      # @raise [RuntimeError] exceptions are raised if there is no file, if it refers to methods that don't exist, or if it does not contain a Hash
      def load_from_json(file)
        if File.exists?(file)
          data = JSON.parse(File.read(file))
          raise "Hash required. Got '#{data.class}' when parsing '#{file}'" unless data.is_a?(Hash)
          data.each do |key, value|
            if self.respond_to?(key)
              self.send(key, value)
            else
              fail "Component does not have a '#{key}' method to invoke. Maybe your bespoke json has a typo?"
            end
          end
        else
          fail "Cannot load component data from '#{file}'. It does not exist."
        end
      end

      # build_requires adds a requirements to the list of build time dependencies
      # that will need to be fetched from an external source before this component
      # can be built. build_requires can also be satisfied by other components in
      # the same project.
      #
      # @param build_requirement [String] a library or other component that is required to build the current component
      def build_requires(build_requirement)
        @component.build_requires << build_requirement
      end

      # requires adds a requirement to the list of runtime requirements for the
      # component
      #
      # @param requirement [String] a package that is required at runtime for this component
      def requires(requirement)
        @component.requires << requirement
      end

      # Indicates that this component replaces a system level package. Replaces can be collected and used by the project and package.
      #
      # @param replacement [String] a package that is replaced with this component
      # @param version [String] the version of the package that is replaced
      def replaces(replacement, version = nil)
        @component.replaces << OpenStruct.new(:replacement => replacement, :version => version)
      end

      # Indicates that this component provides a system level package. Provides can be collected and used by the project and package.
      #
      # @param provide [String] a package that is provided with this component
      # @param version [String] the version of the package that is provided with this component
      def provides(provide, version = nil)
        @component.provides << OpenStruct.new(:provide => provide, :version => version)
      end

      # install_service adds the commands to install the various files on
      # disk during the package build and registers the service with the project
      #
      # @param service_file [String] path to the service file relative to the source
      # @param default_file [String] path to the default file relative to the source
      # @param service_name [String] name of the service
      # @param service_type [String] type of the service (network, application, system, etc)
      def install_service(service_file, default_file = nil, service_name = @component.name, service_type: nil)
        case @component.platform.servicetype
        when "sysv"
          target_service_file = File.join(@component.platform.servicedir, service_name)
          target_default_file = File.join(@component.platform.defaultdir, service_name)
          target_mode = '0755'
          default_mode = '0644'
        when "systemd"
          target_service_file = File.join(@component.platform.servicedir, "#{service_name}.service")
          target_default_file = File.join(@component.platform.defaultdir, service_name)
          target_mode = '0644'
          default_mode = '0644'
        when "launchd"
          target_service_file = File.join(@component.platform.servicedir, "#{service_name}.plist")
          target_mode = '0644'
          default_mode = '0644'
        when "smf"
          target_service_file = File.join(@component.platform.servicedir, service_type.to_s, "#{service_name}.xml")
          target_default_file = File.join(@component.platform.defaultdir, service_name)
          target_mode = '0644'
          default_mode = '0755'
        when "aix"
          @component.service = OpenStruct.new(:name => service_name, :service_command => File.read(service_file).chomp)
          # Return here because there is no file to install, just a string read in
          return
        else
          fail "Don't know how to install the #{@component.platform.servicetype}. Please teach #install_service how to do this."
        end

        # Install the service and default files
        install_file(service_file, target_service_file, mode: target_mode)

        if default_file
          install_file(default_file, target_default_file, mode: default_mode)
          configfile target_default_file
        end

        # Register the service for use in packaging
        @component.service = OpenStruct.new(:name => service_name, :service_file => target_service_file)
      end

      # Copies a file from source to target during the install phase of the component
      #
      # @param source [String] path to the file to copy
      # @param target [String] path to the desired target of the file
      # @param owner  [String] owner of the file
      # @param group  [String] group owner of the file
      def install_file(source, target, mode: '0644', owner: nil, group:  nil)
        @component.install << "#{@component.platform.install} -d '#{File.dirname(target)}'"
        @component.install << "cp -p '#{source}' '#{target}'"
        @component.add_file Vanagon::Common::Pathname.file(target, mode: mode, owner: owner, group: group)
      end

      # Marks a file as a configfile to ensure that it is not overwritten on
      # upgrade if it has been modified
      #
      # @param file [String] name of the configfile
      def configfile(file)
        # I AM SO SORRY
        @component.delete_file "#{file}"
        if @component.platform.name =~ /solaris-10|osx/
          @component.install << "mv '#{file}' '#{file}.pristine'"
          @component.add_file Vanagon::Common::Pathname.configfile("#{file}.pristine")
        else
          @component.add_file Vanagon::Common::Pathname.configfile(file)
        end
      end

      # Shorthand to install a file and mark it as a configfile
      #
      # @param source [String] path to the configfile to copy
      # @param target [String] path to the desired target of the configfile
      def install_configfile(source, target)
        install_file(source, target)
        configfile(target)
      end

      # link will add a command to the install to create a symlink from source to target
      #
      # @param source [String] path to the file to symlink
      # @param target [String] path to the desired symlink
      def link(source, target)
        @component.install << "#{@component.platform.install} -d '#{File.dirname(target)}'"
        @component.install << "ln -s '#{source}' '#{target}'"
        @component.add_file Vanagon::Common::Pathname.file(target)
      end

      # Sets the version for the component
      #
      # @param ver [String] version of the component
      def version(ver)
        @component.version = ver
      end

      # Sets the url for the source of this component
      #
      # @param the_url [String] the url to the source for this component
      def url(the_url)
        @component.url = the_url
      end

      # Sets the md5 sum to verify the sum of the source
      #
      # @param md5 [String] md5 sum of the source for verification
      def md5sum(md5)
        @component.options[:sum] = md5
      end

      # Sets the ref of the source for use in a git source
      #
      # @param the_ref [String] ref, sha, branch or tag to checkout for a git source
      def ref(the_ref)
        @component.options[:ref] = the_ref
      end

      # This will add a source to the project and put it in the workdir alongside the other sources
      #
      # @param url [String] url of the source
      # @param ref [String] Used for git sources, must be a git ref of some sort
      # @param sum [String] sum used to validate http and file sources
      def add_source(url, ref: nil, sum: nil)
        @component.sources << OpenStruct.new(:url => url, :ref => ref, :sum => sum)
      end

      # Adds a directory to the list of directories provided by the project, to be included in any packages of the project
      #
      # @param dir [String] directory to add to the project
      # @param mode [String] octal mode to apply to the directory
      # @param owner [String] owner of the directory
      # @param group [String] group of the directory
      def directory(dir, mode: nil, owner: nil, group: nil)
        @component.directories << Vanagon::Common::Pathname.new(dir, mode: mode, owner: owner, group: group)
      end

      # Adds a set of environment overrides to the environment for a component.
      # This environment is included in the configure, build and install steps.
      #
      # @param env [Hash] mapping of keys to values to add to the environment for the component
      def environment(env)
        @component.environment.merge!(env)
      end

      # Adds action to run during the preinstall phase of packaging
      #
      # @param pkg_state [Array] the state in which the scripts should execute. Can be
      #   one or multiple of 'install' and 'upgrade'.
      # @param scripts [Array] the Bourne shell compatible scriptlet(s) to execute
      def add_preinstall_action(pkg_state, scripts)
        pkg_state = Array(pkg_state)
        scripts = Array(scripts)

        if pkg_state.empty? || !(pkg_state - ["install", "upgrade"]).empty?
          raise Vanagon::Error, "#{pkg_state} should be an array containing one or more of ['install', 'upgrade']"
        end
        @component.preinstall_actions << OpenStruct.new(:pkg_state => pkg_state, :scripts => scripts)
      end

      # Adds action to run during the postinstall phase of packaging
      #
      # @param pkg_state [Array] the state in which the scripts should execute. Can be
      #   one or multiple of 'install' and 'upgrade'.
      # @param scripts [Array] the Bourne shell compatible scriptlet(s) to execute
      def add_postinstall_action(pkg_state, scripts)
        pkg_state = Array(pkg_state)
        scripts = Array(scripts)

        if pkg_state.empty? || !(pkg_state - ["install", "upgrade"]).empty?
          raise Vanagon::Error, "#{pkg_state} should be an array containing one or more of ['install', 'upgrade']"
        end
        @component.postinstall_actions << OpenStruct.new(:pkg_state => pkg_state, :scripts => scripts)
      end

      # Adds action to run during the preremoval phase of packaging
      #
      # @param pkg_state [Array] the state in which the scripts should execute. Can be
      #   one or multiple of 'removal' and 'upgrade'.
      # @param scripts [Array] the Bourne shell compatible scriptlet(s) to execute
      def add_preremove_action(pkg_state, scripts)
        pkg_state = Array(pkg_state)
        scripts = Array(scripts)

        if pkg_state.empty? || !(pkg_state - ["upgrade", "removal"]).empty?
          raise Vanagon::Error, "#{pkg_state} should be an array containing one or more of ['removal', 'upgrade']"
        end
        @component.preremove_actions << OpenStruct.new(:pkg_state => pkg_state, :scripts => scripts)
      end

      # Adds action to run during the postremoval phase of packaging
      #
      # @param pkg_state [Array] the state in which the scripts should execute. Can be
      #   one or multiple of 'removal' and 'upgrade'.
      # @param scripts [Array] the Bourne shell compatible scriptlet(s) to execute
      def add_postremove_action(pkg_state, scripts)
        pkg_state = Array(pkg_state)
        scripts = Array(scripts)

        if pkg_state.empty? || !(pkg_state - ["upgrade", "removal"]).empty?
          raise Vanagon::Error, "#{pkg_state} should be an array containing one or more of ['removal', 'upgrade']"
        end
        @component.postremove_actions << OpenStruct.new(:pkg_state => pkg_state, :scripts => scripts)
      end
    end
  end
end
