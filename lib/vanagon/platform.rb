require 'vanagon/environment'
require 'vanagon/platform/dsl'

class Vanagon
  class Platform
    # Basic generic information related to a given instance of Platform.
    # e.g. The name we call it, the platform triplet (name-version-arch), etc.
    attr_accessor :name
    attr_accessor :platform_triple
    attr_accessor :architecture
    attr_accessor :os_name
    attr_accessor :os_version
    attr_accessor :codename # this is Debian/Ubuntu specific
    attr_writer   :dist # most likely to be used by rpm

    # The name of the sort of package type that a given platform expects,
    # e.g. msi, rpm,
    attr_accessor :package_type

    # The name of the sort of init system that a given platform uses
    attr_accessor :servicetype
    # Where does a given platform expect to find init scripts/service files?
    # e.g. /etc/init.d, /usr/lib/systemd/system
    attr_accessor :servicedir
    # Where does a given platform's init system expect to find
    # something resembling 'defaults' files. Most likely to apply
    # to Linux systems that use SysV-ish, upstart, or systemd init systems.
    attr_accessor :defaultdir

    # Each of these holds the path or name of the command in question,
    # e.g. `copy = "/usr/local/bin/gcp"`, or `copy = "cp"
    attr_accessor :copy
    attr_accessor :find
    attr_accessor :install
    attr_accessor :make
    attr_accessor :patch
    attr_accessor :rpmbuild # This is RedHat/EL/Fedora/SLES specific
    attr_accessor :sort
    attr_accessor :tar
    attr_accessor :shasum

    # Hold a string containing the values that a given platform
    # should use when a Makefile is run - resolves to the CFLAGS
    # and LDFLAGS variables. This should be changed to take advantage
    # of the Environment, so that we can better leverage Make's
    # Implicit Variables:
    #   https://www.gnu.org/software/make/manual/html_node/Implicit-Variables.html
    # It should also be extended to support CXXFLAGS and CPPFLAGS ASAP.
    attr_accessor :cflags
    attr_accessor :ldflags

    # The overall Environment that a given platform
    # should pass to each component
    attr_accessor :environment

    # Stores an Array of OpenStructs, each representing a complete
    # command to be run to install external the needed toolchains
    # and build dependencies for a given target platform.
    attr_accessor :build_dependencies

    # Stores the local path where retrieved artifacts will be saved.
    attr_accessor :output_dir

    # Stores the local path where source artifacts will be saved.
    attr_accessor :source_output_dir

    # Username to use when connecting to a build target
    attr_accessor :target_user

    # Stores an Array of Strings, which will be passed
    # in as a shell script as part of the provisioning step
    # for a given build target
    attr_accessor :provisioning

    # Determines if a platform should be treated as
    # cross-compiled or natively compiled.
    attr_accessor :cross_compiled

    # Stores a string, pointing at the shell that should be used
    # if a user needs to change the path or name of the shell that
    # Make will run build recipes in.
    attr_accessor :shell

    # A string, containing the script that will be executed on
    # the remote build target to determine how many CPU cores
    # are available on that platform. Vanagon will use that count
    # to determine how many build threads should be initialized
    # for compilations.
    attr_accessor :num_cores

    # Generic engine
    attr_accessor :ssh_port

    # Hardware engine specific
    attr_accessor :build_hosts

    # Always-Be-Scheduling engine specific
    attr_accessor :abs_resource_name

    # VMpooler engine specific
    attr_accessor :vmpooler_template

    # Docker engine specific
    attr_accessor :docker_image

    # AWS engine specific
    attr_accessor :aws_ami
    attr_accessor :aws_user_data
    attr_accessor :aws_shutdown_behavior
    attr_accessor :aws_key_name
    attr_accessor :aws_region
    attr_accessor :aws_key
    attr_accessor :aws_instance_type
    attr_accessor :aws_vpc_id
    attr_accessor :aws_subnet_id

    # Freeform Hash of leftover settings
    attr_accessor :settings

    # Platform names currently contain some information about the platform. Fields
    # within the name are delimited by the '-' character, and this regex can be used to
    # extract those fields.
    PLATFORM_REGEX = /^(.*)-(.*)-(.*)$/

    # Loads a given platform from the configdir
    #
    # @param name [String] the name of the platform
    # @param configdir [String] the path to the platform config file
    # @return [Vanagon::Platform] the platform as specified in the platform config
    # @raise if the instance_eval on Platform fails, the exception is reraised
    def self.load_platform(name, configdir)
      platfile = File.join(configdir, "#{name}.rb")
      dsl = Vanagon::Platform::DSL.new(name)
      dsl.instance_eval(File.read(platfile), platfile, 1)
      dsl._platform
    rescue => e
      $stderr.puts "Error loading platform '#{name}' using '#{platfile}':"
      $stderr.puts e
      $stderr.puts e.backtrace.join("\n")
      raise e
    end

    # Generate the scripts required to add a group to the package generated.
    # This will also update the group if it has changed.
    #
    # @param user [Vanagon::Common::User] the user to reference for the group
    # @return [String] the commands required to add a group to the system
    def add_group(user)
      cmd_args = ["'#{user.group}'"]
      cmd_args.unshift '--system' if user.is_system

      groupadd_args = cmd_args.join "\s"
      groupmod_args = (cmd_args - ["--system"]).join "\s"

      return <<-HERE.undent
        if getent group '#{user.group}' > /dev/null 2>&1; then
          /usr/sbin/groupmod #{groupmod_args}
        else
          /usr/sbin/groupadd #{groupadd_args}
        fi
      HERE
    end

    # Generate the scripts required to add a user to the package generated.
    # This will also update the user if it has changed.
    #
    # @param user [Vanagon::Common::User] the user to create
    # @return [String] the commands required to add a user to the system
    def add_user(user) # rubocop:disable Metrics/AbcSize
      cmd_args = ["'#{user.name}'"]
      cmd_args.unshift "--home '#{user.homedir}'" if user.homedir
      if user.shell
        cmd_args.unshift "--shell '#{user.shell}'"
      elsif user.is_system
        cmd_args.unshift "--shell '/usr/sbin/nologin'"
      end
      cmd_args.unshift "--gid '#{user.group}'" if user.group
      cmd_args.unshift '--system' if user.is_system

      # Collapse the cmd_args array into a string that can be used
      # as an argument to `useradd`
      useradd_args = cmd_args.join "\s"

      # Collapse the cmd_args array into a string that can be used
      # as an argument to `usermod`; If this is a system account,
      # then specify it as such for user addition only (strip
      # --system from usermod_args)
      usermod_args = (cmd_args - ["--system"]).join "\s"

      return <<-HERE.undent
        if getent passwd '#{user.name}' > /dev/null 2>&1; then
          /usr/sbin/usermod #{usermod_args}
        else
          /usr/sbin/useradd #{useradd_args}
        fi
      HERE
    end

    # Platform constructor. Takes just the name. Also sets the @name, @os_name,
    # \@os_version and @architecture instance attributes as a side effect
    #
    # @param name [String] name of the platform
    # @return [Vanagon::Platform] the platform with the given name
    def initialize(name) # rubocop:disable Metrics/AbcSize
      @name = name
      @os_name = os_name
      @os_version = os_version
      @architecture = architecture
      @ssh_port = 22
      # Environments are like Hashes but with specific constraints
      # around their keys and values.
      @environment = Vanagon::Environment.new
      @provisioning = []
      @install ||= "install"
      @target_user ||= "root"
      @find ||= "find"
      @sort ||= "sort"
      @copy ||= "cp"
      @shasum ||= "sha1sum"

      # Our first attempt at defining metadata about a platform
      @cross_compiled ||= false
    end

    def shell
      @shell ||= "/bin/bash"
    end

    # This allows instance variables to be accessed using the hash lookup syntax
    def [](key)
      if instance_variable_get("@#{key}")
        instance_variable_get("@#{key}")
      end
    end

    # Get the output dir for packages. If the output_dir was defined already (by
    # the platform config) then don't change it.
    #
    # @param target_repo [String] optional repo target for built packages defined
    #   at the project level
    # @return [String] relative path to where packages should be output to
    def output_dir(target_repo = "")
      @output_dir ||= File.join(@os_name, @os_version, target_repo, @architecture)
    end

    # Get the source dir for packages. Don't change it if it was already defined
    # by the platform config. Defaults to output_dir unless specified otherwise
    # (RPM specifies this)
    #
    # @param target_repo [String] optional repo target for built source packages
    # defined at the project level
    # @return [String] relative path to where source packages should be output to
    def source_output_dir(target_repo = "")
      @source_output_dir ||= output_dir(target_repo)
    end

    # Get the value of @dist, or derive it from the value of @os_name and @os_version.
    # This is relatively RPM specific but '#codename' is defined in Platform, and that's
    # just as Deb/Ubuntu specific. All of the accessors in the top-level Platform
    # namespace should be refactored, but #dist will live here for now.
    # @return [String] the %dist name that RPM will use to build new RPMs
    def dist
      @dist ||= @os_name.tr('-', '_') + @os_version
    end

    # Sets and gets the name of the operating system for the platform.
    # Also has the side effect of setting the @os_name instance attribute
    #
    # @return [String] the operating system name as specified in the platform
    def os_name
      @os_name ||= @name.match(PLATFORM_REGEX)[1]
    end

    # Sets and gets the version of the operating system for the platform.
    # Also has the side effect of setting the @os_version instance attribute
    #
    # @return [String] the operating system version as specified in the platform
    def os_version
      @os_version ||= @name.match(PLATFORM_REGEX)[2]
    end

    # Sets and gets the architecture of the platform.
    # Also has the side effect of setting the @architecture instance attribute
    #
    # @return [String] the architecture of the platform
    def architecture
      @architecture ||= @name.match(PLATFORM_REGEX)[3]
    end

    # Utility matcher to determine is the platform is a debian variety
    #
    # @return [true, false] true if it is a debian variety, false otherwise
    def is_deb?
      return !!@name.match(/^(debian|ubuntu|cumulus|huaweios)-.*$/)
    end

    # Utility matcher to determine is the platform is a redhat variety or
    # uses rpm under the hood
    #
    # @return [true, false] true if it is a redhat variety or uses rpm
    # under the hood, false otherwise
    def is_rpm?
      return !!@name.match(/^(aix|cisco-wrlinux|el|eos|fedora|sles)-.*$/)
    end

    # Utility matcher to determine is the platform is an enterprise linux variety
    #
    # @return [true, false] true if it is a enterprise linux variety, false otherwise
    def is_el?
      return !!@name.match(/^el-.*$/)
    end

    # Utility matcher to determine is the platform is a sles variety
    #
    # @return [true, false] true if it is a sles variety, false otherwise
    def is_sles?
      return !!@name.match(/^sles-.*$/)
    end

    # Utility matcher to determine is the platform is a fedora variety
    #
    # @return [true, false] true if it is a fedora variety, false otherwise
    def is_fedora?
      return !!@name.match(/^fedora-.*$/)
    end

    # Utility matcher to determine is the platform is an aix variety
    #
    # @return [true, false] true if it is an aix variety, false otherwise
    def is_aix?
      return !!@name.match(/^aix-.*$/)
    end

    # Utility matcher to determine is the platform is an eos variety
    #
    # @return [true, false] true if it is an eos variety, false otherwise
    def is_eos?
      return !!@name.match(/^eos-.*$/)
    end

    # Utility matcher to determine is the platform is a HuaweiOS variety
    #
    # @return [true, false] true if it is a HuaweiOS variety, false otherwise
    def is_huaweios?
      return !!@name.match(/^huaweios-.*$/)
    end

    # Utility matcher to determine is the platform is a cisco-wrlinux
    # variety
    #
    # @return [true, false] true if it is a cisco-wrlinux variety, false
    # otherwise
    def is_cisco_wrlinux?
      return !!@name.match(/^cisco-wrlinux-.*$/)
    end

    # Utility matcher to determine if the platform is an osx variety
    #
    # @deprecated Please use is_macos? instead
    # @return [true, false] true if it is an osx variety, false otherwise
    def is_osx?
      warn "is_osx? is a deprecated method, please use #is_macos? instead."
      is_macos?
    end

    # Utility matcher to determine if the platform is a macos or osx variety
    # is_osx is a deprecated method that calls is_macos
    # We still match for osx currently but this will change
    #
    # @return [true, false] true if it is a macos or osx variety, false otherwise
    def is_macos?
      !!(@name =~ /^macos-.*$/ || @name =~ /^osx-.*$/)
    end

    # Utility matcher to determine is the platform is a solaris variety
    #
    # @return [true, false] true if it is an solaris variety, false otherwise
    def is_solaris?
      return !!@name.match(/^solaris-.*$/)
    end

    # Utility matcher to determine is the platform is a unix variety
    #
    # @return [true, false] true if it is a unix variety, false otherwise
    def is_unix?
      return !!@name.match(/^(solaris|aix|osx)-.*$/)
    end

    # Utility matcher to determine is the platform is a windows variety
    #
    # @return [true, false] true if it is a windows variety, false otherwise
    def is_windows?
      return !!@name.match(/^windows-.*$/)
    end

    # Utility matcher to determine is the platform is a linux variety
    #
    # @return [true, false] true if it is a linux variety, false otherwise
    def is_linux?
      return (!is_windows? && !is_unix?)
    end

    # Utility matcher to determine if the platform is a cross-compiled variety
    #
    # @return [true, false] true if it is a cross-compiled variety, false otherwise
    def is_cross_compiled?
      return @cross_compiled
    end

    # Utility matcher to determine if the platform is a cross-compiled Linux variety.
    # Many of the customizations needed to cross-compile for Linux are similar, so it's
    # useful to group them together vs. other cross-compiled OSes.
    #
    # @return [true, false] true if it is a cross-compiled Linux variety, false otherwise
    def is_cross_compiled_linux?
      return (is_cross_compiled? && is_linux?)
    end

    # Pass in a packaging override. This needs to be implemented for each
    # individual platform so that this input ends up in the right place.
    #
    # @param project
    # @param var the string that should be added to the build script.
    def package_override(project, var)
      fail "I don't know how to set package overrides for #{name}, teach me?"
    end

    # Generic adder for build repositories
    #
    # @param *args [Array<String>] List of arguments to pass on to the platform specific method
    # @raise [Vanagon::Error] an arror is raised if the current platform does not define add_repository
    def add_build_repository(*args)
      if self.respond_to?(:add_repository)
        self.provision_with self.send(:add_repository, *args)
      else
        raise Vanagon::Error, "Adding a build repository not defined for #{name}"
      end
    end

    # Save the generic compiled archive and relevant metadata as packaging
    # output. This will include a json file with all of the components/versions
    # that were built and a bill of materials when relevant. The archive will be
    # a gzipped tarball.
    #
    # @param project The Vanagon::Project to run this on
    # @return array of commands to be run
    def generate_compiled_archive(project)
      name_and_version = "#{project.name}-#{project.version}"
      name_and_version_and_platform = "#{name_and_version}.#{name}"
      final_archive = "output/#{name_and_version_and_platform}.tar.gz"
      archive_directory = "#{project.name}-archive"
      metadata = project.build_manifest_json(true)
      metadata.gsub!(/\n/, '\n')
      [
        "mkdir output",
        "mkdir #{archive_directory}",
        "gunzip -c #{name_and_version}.tar.gz | '#{tar}' -C #{archive_directory} -xf -",
        "rm #{name_and_version}.tar.gz",
        "cd #{archive_directory}/#{name_and_version}; #{tar} cf ../../#{name_and_version_and_platform}.tar `#{find} . -type d`",
        "gzip -9c #{name_and_version_and_platform}.tar > #{name_and_version_and_platform}.tar.gz",
        "echo -e \"#{metadata}\" > output/#{name_and_version_and_platform}.json",
        "cp bill-of-materials output/#{name_and_version_and_platform}-bill-of-materials ||:",
        "cp #{name_and_version_and_platform}.tar.gz output",
        "#{shasum} #{final_archive} > #{final_archive}.sha1"
      ]
    end

    # Set the command to turn the target machine into a builder for vanagon
    #
    # @param command [String] Command to enable the target machine to build packages for the platform
    def provision_with(command)
      provisioning << command
      provisioning.flatten!
    end
  end
end
