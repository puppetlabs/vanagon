require 'vanagon/platform/deb'
require 'vanagon/platform/rpm'
require 'vanagon/platform/rpm/aix'
require 'vanagon/platform/rpm/sles'
require 'vanagon/platform/rpm/wrl'
require 'vanagon/platform/rpm/eos'
require 'vanagon/platform/osx'
require 'vanagon/platform/solaris_10'
require 'vanagon/platform/solaris_11'
require 'vanagon/platform/windows'
require 'securerandom'
require 'uri'

class Vanagon
  class Platform
    class DSL
      # Constructor for the DSL object
      #
      # @param name [String] name of the platform
      # @return [Vanagon::Platform::DSL] A DSL object to describe the {Vanagon::Platform}
      def initialize(platform_name)
        @name = platform_name
      end

      # Primary way of interacting with the DSL. Also a simple factory to get the right platform object.
      #
      # @param name [String] name of the platform
      # @param block [Proc] DSL definition of the platform to call
      def platform(platform_name, &block)
        @platform = case platform_name
                    when /^aix-/
                      Vanagon::Platform::RPM::AIX.new(@name)
                    when /^(cisco-wrlinux|el|fedora)-/
                      Vanagon::Platform::RPM.new(@name)
                    when /^sles-/
                      Vanagon::Platform::RPM::SLES.new(@name)
                    when /^(cumulus|debian|huaweios|ubuntu)-/
                      Vanagon::Platform::DEB.new(@name)
                    when /^eos-/
                      Vanagon::Platform::RPM::EOS.new(@name)
                    when /^osx-/
                      Vanagon::Platform::OSX.new(@name)
                    when /^solaris-10/
                      Vanagon::Platform::Solaris10.new(@name)
                    when /^solaris-11/
                      Vanagon::Platform::Solaris11.new(@name)
                    when /^windows-/
                      Vanagon::Platform::Windows.new(@name)
                    else
                      fail "Platform not implemented for '#{@name}' yet. Please go do so..."
                    end

        yield(self)
        @platform
      end

      # Accessor for the platform.
      #
      # @return [Vanagon::Platform] the platform the DSL methods will be acting against
      def _platform
        @platform
      end

      # All purpose getter. This object, which is passed to the platform block,
      # won't have easy access to the attributes of the @platform, so we make a
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

        @platform.send(attribute)
      end

      def respond_to_missing?(method_name, include_private = false)
        method_name.to_s.start_with?('get_') || super
      end

      # Adds an arbitrary environment variable to a Platform, which will be
      # merged with any environment variables defined by the Project into the
      # rendered Makefile
      def environment(key, value)
        @platform.environment[key] = value
      end

      # Set the path to make for the platform
      #
      # @param make_cmd [String] Full path to the make command for the platform
      def make(make_cmd)
        @platform.make = make_cmd
      end

      # Set the path for Make's SHELL for the platform
      #
      # @param shell_path [String] Full path to the shell Make should use
      def shell(shell_path)
        @platform.shell = shell_path
      end

      # Set the path to tar for the platform
      #
      # @param tar [String] Full path to the tar command for the platform
      def tar(tar_cmd)
        @platform.tar = tar_cmd
      end

      def shasum(sha1sum_command)
        @platform.shasum = sha1sum_command
      end

      # Set the type of package we are going to build for this platform
      #
      # @param pkg_type [String] The type of package we are going to build for this platform
      def package_type(pkg_type)
        @platform.package_type = pkg_type
      end

      # Set the path to find for the platform
      #
      # @param find_cmd [String] Full path to the find command for the platform
      def find(find_cmd)
        @platform.find = find_cmd
      end

      # Set the path to sort for the platform
      #
      # @param sort_cmd [String] Full path to the sort command for the platform
      def sort(sort_cmd)
        @platform.sort = sort_cmd
      end

      # Set the path to copy for the platform
      #
      # @param copy_cmd [String] Full path to the copy command for the platform
      def copy(copy_cmd)
        @platform.copy = copy_cmd
      end

      # Set the cross_compiled flag for the platform
      #
      # @param xcc [Boolean] True if this is a cross-compiled platform
      def cross_compiled(xcc_flag)
        @platform.cross_compiled = !!xcc_flag
      end

      # define an explicit Dist for the platform (most likely used for RPM platforms)
      #
      # @param dist_string [String] the value to use for .dist when building RPMs
      def dist(dist_string)
        @platform.dist = dist_string
      end

      # Set the path to rpmbuild for the platform
      #
      # @param rpmbuild_cmd [String] Full path to rpmbuild with arguments to be used by default
      def rpmbuild(rpmbuild_cmd)
        @platform.rpmbuild = rpmbuild_cmd
      end

      # Set the path to the install command
      # @param install_cmd [String] Full path to install with arguments to be used by default
      def install(install_cmd)
        @platform.install = install_cmd
      end

      # Set the path to patch for the platform
      #
      # @param patch_cmd [String] Full path to the patch command for the platform
      def patch(patch_cmd)
        @platform.patch = patch_cmd
      end

      # Sets the command to retrieve the number of cores available on a platform.
      #
      # @param num_cores_cmd [String] the command to retrieve the number of available cores on a platform.
      def num_cores(num_cores_cmd)
        @platform.num_cores = num_cores_cmd
      end

      # Set the command to turn the target machine into a builder for vanagon
      #
      # @param command [String] Command to enable the target machine to build packages for the platform
      def provision_with(command)
        @platform.provision_with(command)
      end

      # Set the command to install any needed build dependencies for the target machine
      #
      # @param command [String] Command to install build dependencies for the target machine
      # @param suffix [String] shell to be run after the main command
      def install_build_dependencies_with(command, suffix = nil)
        @platform.build_dependencies = OpenStruct.new({ :command => command, :suffix => suffix })
      end

      # Set the directory where service files or init scripts live for the platform
      #
      # @param dir [String] Directory where service files live on the platform
      def servicedir(dir)
        @platform.servicedir = dir
      end

      # Set the directory where default or sysconfig files live for the platform
      #
      # @param dir [String] Directory where default or sysconfig files live on the platform
      def defaultdir(dir)
        @platform.defaultdir = dir
      end

      # Set the servicetype for the platform so that services can be installed correctly.
      #
      # @param type [String] service type for the platform ('sysv' for example)
      def servicetype(type)
        @platform.servicetype = type
      end

      # Set the list of possible host to perform a build on (when not using
      # pooler or CLI flags)
      #
      # @param type [Array] the names of the hosts (must be resolvable)
      # @rase ArgumentError if builds_hosts has no arguments
      def build_hosts(*args)
        raise ArgumentError, "build_hosts requires at least one host to be a build target." if args.empty?
        @platform.build_hosts = Array(args).flatten
      end

      # Because single vs plural is annoying to remember
      alias_method :build_host, :build_hosts

      # Set the name of this platform as the vm pooler expects it
      #
      # @param name [String] name of the target template to use from the vmpooler
      def vmpooler_template(template_name)
        @platform.vmpooler_template = template_name
      end

      # Set the name of this platform as the vm pooler expects it
      #
      # @param name [String] name that the pooler uses for this platform
      # @deprecated Please use vmpooler_template instead, this will be removed in a future vanagon release.
      def vcloud_name(cloud_name)
        warn "vcloud_name is a deprecated platform DSL method, and will be removed in a future vanagon release. Please use vmpooler_template instead."
        self.vmpooler_template(cloud_name)
      end

      # Set the name of this platform as always-be-scheduling (ABS) expects it
      #
      # @param name [String] name of the platform to request from always-be-scheduling
      def abs_resource_name(resource_name)
        @platform.abs_resource_name = resource_name
      end

      # Set the name of the docker image to use
      #
      # @param name [String] name of the docker image to use
      def docker_image(image_name)
        @platform.docker_image = image_name
      end

      # Set the ami for the platform to use
      #
      # @param ami [String] the ami id used.
      def aws_ami(ami_name)
        @platform.aws_ami = ami_name
      end

      # Set the user data used in AWS to do setup. Like cloud-config
      #
      # @param userdata [String] a string used to send to the node to do the intial setup
      def aws_user_data(userdata)
        @platform.aws_user_data = userdata
      end

      # Set the region, this defaults to us-east-1
      #
      # @param region [String] a string used to setup the region
      def aws_region(region = 'us-east-1')
        @platform.aws_region = region
      end

      # Set the shutdown behavior for aws. This will default to terminate the instance on shutdown
      #
      # @param shutdown_behavior [String] a string used to set the shutdown behavior
      def aws_shutdown_behavior(shutdown_behavior = 'terminate')
        @platform.aws_shutdown_behavior = shutdown_behavior
      end

      # Set the key_name used. This should already exist on AWS.
      #
      # @param key_name [String] this defaults to the keyname vanagon. Can be set to any
      def aws_key_name(key_name = 'vanagon')
        @platform.aws_key_name = key_name
      end

      # Set the instaince type. This defaults to t1.micro which is the free instance
      #
      # @param instance_type [String] a string to define the instaince type
      def aws_instance_type(instance_type = 't1.micro')
        @platform.aws_instance_type = instance_type
      end

      # Set the subnet_id. Use this to setup a subnet for your VPC to use.
      #
      # @param subnet_id[String] a string to define the subnet_id in AWS
      def aws_subnet_id(subnet_id)
        @platform.aws_subnet_id = subnet_id
      end

      # Set the port for ssh to use if it's not 22
      #
      # @param port [Integer] port number for ssh
      def ssh_port(port = 22)
        @platform.ssh_port = port
      end

      # Set the target user to login with. Defaults to root.
      #
      # @param user[String] a user string to login with.
      def target_user(user = "root")
        @platform.target_user = user
      end

      # Set the target ip address or hostname to start build
      #
      # @param target_host[String] a host string to login with.
      def target_host(target_host)
        @platform.target_host = target_host
      end

      # Set the platform_triple for the platform
      #
      # @param triple[String] platform_triple for use in building out compiled
      # tools and cross-compilation
      def platform_triple(triple)
        @platform.platform_triple = triple
      end

      # Set any codename this platform may have (debian for example)
      #
      # @param codename [String] codename for this platform (squeeze for example)
      def codename(codename)
        @platform.codename = codename
      end

      def output_dir(directory)
        @platform.output_dir = directory
      end

      def source_output_dir(directory)
        @platform.source_output_dir = directory
      end

      # Helper to setup a apt repository on a target system
      #
      # @param definition [String] the repo setup file, must be a valid uri, fetched with curl
      # @param gpg_key [String] optional gpg key to be fetched via curl and installed
      # @deprecated Please use the add_build_repository DSL method instead. apt_repo will be removed in a future vanagon release.
      def apt_repo(definition, gpg_key = nil)
        warn "Please use the add_build_repository DSL method instead. apt_repo will be removed in a future vanagon release."
        self.add_build_repository(definition, gpg_key)
      end

      # Helper to setup a yum repository on a target system
      #
      # @param definition [String] the repo setup URI or RPM file
      # @deprecated Please use the add_build_repository DSL method instead. yum_repo will be removed in a future vanagon release.
      def yum_repo(definition)
        warn "Please use the add_build_repository DSL method instead. yum_repo will be removed in a future vanagon release."
        self.add_build_repository(definition)
      end

      # Helper to setup a zypper repository on a target system
      #
      # @param definition [String] the repo setup URI or RPM file
      # @deprecated Please use the add_build_repository DSL method instead. zypper_repo will be removed in a future vanagon release.
      def zypper_repo(definition)
        warn "Please use the add_build_repository DSL method instead. zypper_repo will be removed in a future vanagon release."
        self.add_build_repository(definition)
      end

      # Generic adder for build repositories
      #
      # @param *args [Array<String>] List of arguments to pass on to the platform specific method
      # @raise [Vanagon::Error] an arror is raised if the current platform does not define add_repository
      def add_build_repository(*args)
        @platform.add_build_repository(*args)
      end
    end
  end
end
