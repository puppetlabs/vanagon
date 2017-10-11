require 'vanagon/component'
require 'vanagon/patch'
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
        yield(self, @component.settings, @component.platform)
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
      def method_missing(method_name, *args)
        attribute_match = method_name.to_s.match(/get_(.*)/)
        if attribute_match
          attribute = attribute_match.captures.first
        else
          super
        end

        @component.send(attribute)
      end

      def respond_to_missing?(method_name, include_private = false)
        method_name.to_s.start_with?('get_') || super
      end

      # Set or add to the configure call for the component. The commands required to configure the component before building it.
      #
      # @param block [Proc] the command(s) required to configure the component
      def configure(&block)
        @component.configure << yield
      end

      # Set or add to the build call for the component. The commands required to build the component before testing/installing it.
      #
      # @param block [Proc] the command(s) required to build the component
      def build(&block)
        @component.build << yield
      end

      # Set or add to the check call for the component. The commands required to test the component before installing it.
      #
      # @param block [Proc] the command(s) required to test the component
      def check(&block)
        @component.check << yield
      end

      # Set or add to the install call for the component. The commands required to install the component.
      #
      # @param block [Proc] the command(s) required to install the component
      def install(&block)
        @component.install << yield
      end

      # Add a patch to the list of patches to apply to the component's source after unpacking
      #
      # @param patch [String] Path to the patch that should be applied
      # @param destination [String] Path to the location where the patch should be applied
      # @param strip [String, Integer] directory levels to skip in applying patch
      # @param fuzz [String, Integer] levels of context miss to ignore in applying patch
      # @param after [String] the location in the makefile where the patch command should be run
      def apply_patch(patch, destination: @component.dirname, strip: 1, fuzz: 0, after: 'unpack')
        @component.patches << Vanagon::Patch.new(patch, strip, fuzz, after, destination)
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

      # Indicates that this component conflicts with another package,
      # so both cannot be installed at the same time. Conflicts can be
      # collected and used by the project and package.
      #
      # @param pkgname [String] name of the package which conflicts with this component
      # @param version [String] the version of the package that conflicts with this component
      def conflicts(pkgname, version = nil)
        @component.conflicts << OpenStruct.new(:pkgname => pkgname, :version => version)
      end

      # install_service adds the commands to install the various files on
      # disk during the package build and registers the service with the project
      #
      # @param service_file [String] path to the service file relative to the source
      # @param default_file [String] path to the default file relative to the source
      # @param service_name [String] name of the service
      # @param service_type [String] type of the service (network, application, system, etc)
      # @param link_target [String] executable service file should be linked to
      def install_service(service_file, default_file = nil, service_name = @component.name, service_type: nil, link_target: nil) # rubocop:disable Metrics/AbcSize
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
        when "windows"
          @component.service = OpenStruct.new(\
            :bindir_id => "#{service_name.gsub(/[^A-Za-z0-9]/, '').upcase}BINDIR", \
            :service_file => service_file, \
            :component_group_id => "#{service_name.gsub(/[^A-Za-z0-9]/, '')}Component"\
          )
          # return here as we are just collecting the name of the service file to put into the harvest filter list.
          return
        else
          fail "Don't know how to install the #{@component.platform.servicetype}. Please teach #install_service how to do this."
        end

        # Install the service and default files
        if link_target
          install_file(service_file, link_target, mode: target_mode)
          link link_target, target_service_file
        else
          install_file(service_file, target_service_file, mode: target_mode)
        end

        if default_file
          install_file(default_file, target_default_file, mode: default_mode)
          configfile target_default_file
        end

        # Register the service for use in packaging
        @component.service = OpenStruct.new(:name => service_name, :service_file => target_service_file, :type => service_type)
      end

      # Copies a file from source to target during the install phase of the component
      #
      # @param source [String] path to the file to copy
      # @param target [String] path to the desired target of the file
      # @param owner  [String] owner of the file
      # @param group  [String] group owner of the file
      def install_file(source, target, mode: nil, owner: nil, group: nil) # rubocop:disable Metrics/AbcSize
        @component.install << "#{@component.platform.install} -d '#{File.dirname(target)}'"
        @component.install << "#{@component.platform.copy} -p '#{source}' '#{target}'"

        if @component.platform.is_windows?
          unless mode.nil? && owner.nil? && group.nil?
            warn "You're trying to set the mode, owner, or group for windows. I don't know how to do that, ignoring!"
          end
        else
          mode ||= '0644'
          @component.install << "chmod #{mode} '#{target}'"
        end
        @component.add_file Vanagon::Common::Pathname.file(target, mode: mode, owner: owner, group: group)
      end

      # Marks a file as a configfile to ensure that it is not overwritten on
      # upgrade if it has been modified
      #
      # @param file [String] name of the configfile
      def configfile(file, mode: nil, owner: nil, group: nil)
        # I AM SO SORRY
        @component.delete_file file
        if @component.platform.name =~ /solaris-10|osx/
          @component.install << "mv '#{file}' '#{file}.pristine'"
          @component.add_file Vanagon::Common::Pathname.configfile("#{file}.pristine", mode: mode, owner: owner, group: group)
        else
          @component.add_file Vanagon::Common::Pathname.configfile(file, mode: mode, owner: owner, group: group)
        end
      end

      # Shorthand to install a file and mark it as a configfile
      #
      # @param source [String] path to the configfile to copy
      # @param target [String] path to the desired target of the configfile
      def install_configfile(source, target, mode: '0644', owner: nil, group: nil)
        install_file(source, target, mode: mode, owner: owner, group: group)
        configfile(target, mode: mode, owner: owner, group: group)
      end

      # link will add a command to the install to create a symlink from source to target
      #
      # @param source [String] path to the file to symlink
      # @param target [String] path to the desired symlink
      def link(source, target)
        @component.install << "#{@component.platform.install} -d '#{File.dirname(target)}'"
        # Use a bash conditional to only create the link if it doesn't already point to the correct source.
        # This allows rerunning the install step to be idempotent, rather than failing because the link
        # already exists.
        @component.install << "([[ '#{target}' -ef '#{source}' ]] || ln -s '#{source}' '#{target}')"
        @component.add_file Vanagon::Common::Pathname.file(target)
      end

      # Sets the version for the component
      #
      # @param ver [String] version of the component
      def version(ver)
        @component.version = ver
      end

      # Sets the canonical URL or URI for the upstream source of this component
      #
      # @param uri [String, URI] a URL or URI describing a canonical location
      #   for a component's source code or artifact
      def url(uri)
        @component.url = uri.to_s
      end

      # Sets a mirror url for the source of this component
      #
      # @param url [String] a mirror url to use as the source for this component.
      #   Can be called more than once to add multiple mirror URLs.
      def mirror(url)
        @component.mirrors << url
      end

      def sum(value)
        type = __callee__.to_s.gsub(/sum$/, '')
        @component.options[:sum] = value
        @component.options[:sum_type] = type
      end
      alias_method :md5sum, :sum
      alias_method :sha1sum, :sum
      alias_method :sha256sum, :sum
      alias_method :sha512sum, :sum

      # Sets the ref of the source for use in a git source
      #
      # @param the_ref [String] ref, sha, branch or tag to checkout for a git source
      def ref(the_ref)
        @component.options[:ref] = the_ref
      end

      # Set a build dir relative to the source directory.
      #
      # The build dir will be created before the configure block runs and configure/build/install commands will be run
      # in the build dir.
      #
      # @example
      #   pkg.build_dir "build"
      #   pkg.source "my-cmake-project" # Will create the path "my-cmake-project/build"
      #   pkg.configure { ["cmake .."] }
      #   pkg.build { ["make -j 3"] }
      #   pkg.install { ["make install"] }
      #
      # @param path [String] The build directory to use for building the project
      def build_dir(path)
        if Pathname.new(path).relative?
          @component.build_dir = path
        else
          raise Vanagon::Error, "build_dir should be a relative path, but '#{path}' looks to be absolute."
        end
      end

      # Set a source dir
      #
      # The build dir will be created when the source archive is unpacked. This
      # should be used when the unpacked directory name does not match the
      # source archive name.
      #
      # @example
      #   pkg.url "http://the-internet.com/a-silly-name-that-unpacks-into-not-this.tar.gz"
      #   pkg.dirname "really-cool-directory"
      #   pkg.configure { ["cmake .."] }
      #   pkg.build { ["make -j 3"] }
      #   pkg.install { ["make install"] }
      #
      # @param path [String] The build directory to use for building the project
      def dirname(path)
        if Pathname.new(path).relative?
          @component.dirname = path
        else
          raise Vanagon::Error, "dirname should be a relative path, but '#{path}' looks to be absolute."
        end
      end


      # This will add a source to the project and put it in the workdir alongside the other sources
      #
      # @param uri [String] uri of the source
      # @param [Hash] options optional keyword arguments used to instatiate a new source
      #   @option opts [String] :sum
      #   @option opts [String] :ref
      def add_source(uri, **options)
        @component.sources << OpenStruct.new(options.merge({ url: uri }))
      end

      # Adds a directory to the list of directories provided by the project, to be included in any packages of the project
      #
      # @param dir [String] directory to add to the project
      # @param mode [String] octal mode to apply to the directory
      # @param owner [String] owner of the directory
      # @param group [String] group of the directory
      def directory(dir, mode: nil, owner: nil, group: nil) # rubocop:disable Metrics/AbcSize
        install_flags = ['-d']
        if @component.platform.is_windows?
          unless mode.nil? && owner.nil? && group.nil?
            warn "You're trying to set the mode, owner, or group for windows. I don't know how to do that, ignoring!"
          end
        else
          install_flags << "-m '#{mode}'" unless mode.nil?
        end
        @component.install << "#{@component.platform.install} #{install_flags.join(' ')} '#{dir}'"
        @component.directories << Vanagon::Common::Pathname.new(dir, mode: mode, owner: owner, group: group)
      end

      # Adds a set of environment overrides to the environment for a component.
      # This environment is included in the configure, build and install steps.
      #
      # @param env [Hash] mapping of keys to values to add to the environment for the component
      def environment(*env) # rubocop:disable Metrics/AbcSize
        if env.size == 1 && env.first.is_a?(Hash)
          warn <<-eos.undent
            the component DSL method signature #environment({Key => Value}) is deprecated
            and will be removed by Vanagon 1.0.0.

            Please update your project configurations to use the form:
              #environment(key, value)
          eos
          return @component.environment.merge!(env.first)
        elsif env.size == 2
          return @component.environment[env.first] = env.last
        end
        raise ArgumentError, <<-eos.undent
          component DSL method #environment only accepts a single Hash (deprecated)
          or a key-value pair (preferred):
            environment({"KEY" => "value"})
            environment("KEY", "value")
        eos
      end

      # Checks that the array of pkg_state is valid (install AND/OR upgrade).
      # Returns vanagon error if invalid
      #
      # @param pkg_state [Array] array of pkg_state input to test
      def check_pkg_state_array(pkg_state)
        if pkg_state.empty? || (pkg_state - ["install", "upgrade"]).any?
          raise Vanagon::Error, "#{pkg_state} should be an array containing one or more of ['install', 'upgrade']"
        end
      end

      # Adds action to run during the preinstall phase of packaging
      #
      # @param pkg_state [String, Array] the package state during which the scripts should execute.
      #   Accepts either a single string ("install" or "upgrade"), or an Array of Strings (["install", "upgrade"]).
      # @param scripts [Array] the Bourne shell compatible scriptlet(s) to execute
      def add_preinstall_action(pkg_state, scripts)
        pkg_state = Array(pkg_state)
        scripts = Array(scripts)
        check_pkg_state_array(pkg_state)
        @component.preinstall_actions << OpenStruct.new(:pkg_state => pkg_state, :scripts => scripts)
      end

      # Adds trigger for scripts to be run on specified pkg_state.
      #
      # @param pkg_state [String, Array] the package state during which the scripts should execute.
      #   Accepts either a single string ("install" or "upgrade"), or an Array of Strings (["install", "upgrade"]).
      # @param scripts [Array] the rpm pkg scriptlet(s) to execute
      # @param pkg [String] the package the trigger will be set in
      def add_rpm_install_triggers(pkg_state, scripts, pkg)
        pkg_state = Array(pkg_state)
        scripts = Array(scripts)
        check_pkg_state_array(pkg_state)
        @component.install_triggers << OpenStruct.new(:pkg_state => pkg_state, :scripts => scripts, :pkg => pkg)
      end

      # Adds interest trigger based on the specified packaging state and interest name.
      #
      # @param pkg_state [String, Array] the package state during which the scripts should execute.
      #   Accepts either a single string ("install" or "upgrade"), or an Array of Strings (["install", "upgrade"]).
      # @param scripts [Array] the scripts to run for the interest trigger
      # @param interest_name [String] the name of the interest trigger
      def add_debian_interest_triggers(pkg_state, scripts, interest_name)
        pkg_state = Array(pkg_state)
        scripts = Array(scripts)
        check_pkg_state_array(pkg_state)
        @component.interest_triggers << OpenStruct.new(:pkg_state => pkg_state, :scripts => scripts, :interest_name => interest_name)
      end

      # Adds activate trigger name to be watched
      #
      # @param activate_name [String] the activate trigger name
      def add_debian_activate_triggers(activate_name)
        @component.activate_triggers << OpenStruct.new(:activate_name => activate_name)
      end

      # Adds action to run during the postinstall phase of packaging
      #
      # @param pkg_state [Array] the state in which the scripts should execute. Can be
      #   one or multiple of 'install' and 'upgrade'.
      # @param scripts [Array] the Bourne shell compatible scriptlet(s) to execute
      def add_postinstall_action(pkg_state, scripts)
        pkg_state = Array(pkg_state)
        scripts = Array(scripts)
        check_pkg_state_array(pkg_state)
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

      def license(license)
        @component.license = license
      end

      def install_only(install_only)
        @component.install_only = install_only
      end
    end
  end
end
