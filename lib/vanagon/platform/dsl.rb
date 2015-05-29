require 'vanagon/platform/deb'
require 'vanagon/platform/rpm'
require 'vanagon/platform/osx'
require 'vanagon/platform/solaris_10'
require 'vanagon/platform/solaris_11'
require 'securerandom'
require 'uri'

class Vanagon
  class Platform
    class DSL
      # Constructor for the DSL object
      #
      # @param name [String] name of the platform
      # @return [Vanagon::Platform::DSL] A DSL object to describe the {Vanagon::Platform}
      def initialize(name)
        @name = name
      end

      # Primary way of interacting with the DSL. Also a simple factory to get the right platform object.
      #
      # @param name [String] name of the platform
      # @param block [Proc] DSL definition of the platform to call
      def platform(name, &block)
        @platform = case name
                    when /^(el|fedora|sles|eos|nxos|aix)-/
                      Vanagon::Platform::RPM.new(@name)
                    when /^(debian|ubuntu|cumulus)-/
                      Vanagon::Platform::DEB.new(@name)
                    when /^osx-/
                      Vanagon::Platform::OSX.new(@name)
                    when /^solaris-10/
                      Vanagon::Platform::Solaris10.new(@name)
                    when /^solaris-11/
                      Vanagon::Platform::Solaris11.new(@name)
                    else
                      fail "Platform not implemented for '#{@name}' yet. Please go do so..."
                    end

        block.call(self)
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
      def method_missing(method, *args)
        attribute_match = method.to_s.match(/get_(.*)/)
        if attribute_match
          attribute = attribute_match.captures.first
        else
          super
        end

        @platform.send(attribute)
      end

      # Set the path to make for the platform
      #
      # @param make_cmd [String] Full path to the make command for the platform
      def make(make_cmd)
        @platform.make = make_cmd
      end

      # Set the path to tar for the platform
      #
      # @param tar [String] Full path to the tar command for the platform
      def tar(tar_cmd)
        @platform.tar = tar_cmd
      end

      # Set the path to rpmbuild for the platform
      #
      # @param rpmbuild_cmd [String] Full path to rpmbuild with arguments to be used by default
      def rpmbuild(rpmbuild_cmd)
        @platform.rpmbuild = rpmbuild_cmd
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
        @platform.provisioning << command
      end

      # Set the command to install any needed build dependencies for the target machine
      #
      # @param command [String] Command to install build dependencies for the target machine
      # @param suffix [String] shell to be run after the main command
      def install_build_dependencies_with(command, suffix = nil)
        @platform.build_dependencies = OpenStruct.new({:command => command, :suffix => suffix})
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

      # Set the name of this platform as the vm pooler expects it
      #
      # @param name [String] name that the pooler uses for this platform
      def vcloud_name(name)
        @platform.vcloud_name = name
      end

      # Set the name of the docker image to use
      #
      # @param name [String] name of the docker image to use
      def docker_image(name)
        @platform.docker_image = name
      end

      # Set the port for ssh to use if it's not 22
      #
      # @param port [Integer] port number for ssh
      def ssh_port(port = 22)
        @platform.ssh_port = port
      end

      # Set any codename this platform may have (debian for example)
      #
      # @param name [String] codename for this platform (squeeze for example)
      def codename(name)
        @platform.codename = name
      end

      # Allow package installation on AIX.
      #   Since AIX doesn't have network dependency resolution, we'll just use
      #   rpm. This method basically just accepts a mirror and then the
      #   complete RPM filenames to install. If the package requires other
      #   packages, you should specificy them as an array. Otherwise you can
      #   install a signle or multiple packages at a time.
      #
      # @param mirror [String]  The url where you have your AIX rpm packages
      #   (e.g. http://int-resources.corp.puppetlabs.net/AIX_MIRROR)
      # @param packages [String or Array] Single string or list of packages to install
      def aix_package(mirror, packages)
        installation_string = ""
        if packages.respond_to? :each
          packages.each do |pkg|
            installation_string << " " +  mirror + '/' +  pkg
          end
          self.provision_with "rpm -Uvh --replacepkgs #{installation_string}"
        else
          self.provision_with "rpm -Uvh --replacepkgs #{mirror}/#{packages}"
        end
      end

      # Helper to setup a apt repository on a target system
      #
      # @param definition [String] the repo setup file, must be a valid uri, fetched with curl
      # @param gpg_key [String] optional gpg key to be fetched via curl and installed
      def apt_repo(definition, gpg_key = nil)
        # i.e., definition = http://builds.puppetlabs.lan/puppet-agent/0.2.1/repo_configs/deb/pl-puppet-agent-0.2.1-wheezy.list
        # parse the definition and gpg_key if set to ensure they are both valid URIs
        definition = URI.parse definition
        gpg_key = URI.parse gpg_key if gpg_key

        self.provision_with "apt-get -qq install curl"
        if definition.scheme =~ /^(http|ftp)/
          if File.extname(definition.path) == '.deb'
            # repo definition is an deb (like puppetlabs-release)
            self.provision_with "curl -o local.deb '#{definition}'; dpkg -i local.deb; rm -f local.deb"
          else
            reponame = "#{SecureRandom.hex}-#{File.basename(definition.path)}"
            reponame = "#{reponame}.list" if File.extname(reponame) != '.list'
            self.provision_with "curl -o '/etc/apt/sources.list.d/#{reponame}' '#{definition}'"
          end
        end

        if gpg_key
          gpgname = "#{SecureRandom.hex}-#{File.basename(gpg_key.path)}"
          gpgname = "#{gpgname}.gpg" if gpgname !~ /\.gpg$/
          self.provision_with "curl -o '/etc/apt/trusted.gpg.d/#{gpgname}' '#{gpg_key}'"
        end

        self.provision_with "apt-get -qq update"
      end

      # Helper to setup a yum repository on a target system
      #
      # @param definition [String] the repo setup URI or RPM file
      def yum_repo(definition)
        definition = URI.parse definition

        self.provision_with "yum -y install curl"
        if definition.scheme =~ /^(http|ftp)/
          if File.extname(definition.path) == '.rpm'
            # repo definition is an rpm (like puppetlabs-release)
            if @platform.os_version.to_i < 6
              # This can likely be done with just rpm itself (minus curl) however
              # with a http_proxy curl has many more options avavailable for
              # usage than rpm raw does. So for the most compatibility, we have
              # chosen curl.
              self.provision_with "curl -o local.rpm '#{definition}'; rpm -Uvh local.rpm; rm -f local.rpm"
            else
              self.provision_with "yum localinstall -y '#{definition}'"
            end
          else
            reponame = "#{SecureRandom.hex}-#{File.basename(definition.path)}"
            reponame = "#{reponame}.repo"  if File.extname(reponame) != '.repo'
            self.provision_with "curl -o '/etc/yum.repos.d/#{reponame}' '#{definition}'"
          end
        end
      end

      # Helper to setup a zypper repository on a target system
      #
      # @param definition [String] the repo setup URI or RPM file
      def zypper_repo(definition)
        definition = URI.parse definition
        if @platform.os_version == '10'
          flag = 'sa'
        else
          flag = 'ar'
        end
        self.provision_with "yes | zypper -n --no-gpg-checks install curl"
        if definition.scheme =~ /^(http|ftp)/
          if File.extname(definition.path) == '.rpm'
            # repo definition is an rpm (like puppetlabs-release)
            self.provision_with "curl -o local.rpm '#{definition}'; rpm -Uvh local.rpm; rm -f local.rpm"
          else
            self.provision_with "yes | zypper -n --no-gpg-checks #{flag} -t YUM --repo '#{definition}'"
          end
        end
      end
    end
  end
end
