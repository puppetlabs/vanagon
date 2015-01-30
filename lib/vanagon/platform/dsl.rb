require 'vanagon/platform/deb'
require 'vanagon/platform/rpm'
require 'digest/md5'

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
                    when /^(el|sles|eos)-/
                      Vanagon::Platform::RPM.new(@name)
                    when /^(debian|ubuntu)-/
                      Vanagon::Platform::DEB.new(@name)
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
      def install_build_dependencies_with(command)
        @platform.build_dependencies = command
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

      # Set any codename this platform may have (debian for example)
      #
      # @param name [String] codename for this platform (squeeze for example)
      def codename(name)
        @platform.codename = name
      end

      # Helper to setup a apt repository on a target system
      #
      # @param definition [String] the repo setup URI or DEB file
      # @param reponame [String] optional name of the repo, defaults to 'somerepo-md5'
      def apt_repo(definition, reponame = "somerepo" )
        # Add a semi-random suffix to the default in case more than one repo is specificied to use the default
        reponame = reponame + "-" +   Digest::MD5.hexdigest(definition)[0..6] if reponame == 'somerepo'
        self.provision_with "apt-get -qq install curl"
        if ( definition =~ /^http/ and definition !~ /deb$/ )
          # Repo definition is a URI e.g.
          # http://builds.puppetlabs.lan/puppet-agent/0.2.1/repo_configs/deb/pl-puppet-agent-0.2.1-wheezy.list
          reponame = reponame + '.list'  if reponame !~ /\.list$/
          self.provision_with "curl -o '/etc/apt/sources.list.d/#{reponame}' '#{definition}'; apt-get -qq update"
        else ( definition =~ /deb$/ )
          # repo definition is an deb (like puppetlabs-release)
          self.provision_with "curl -o local.deb '#{definition}'; dpkg -i local.deb; rm -f local.deb"
        end
      end

      # Helper to setup a yum repository on a target system
      #
      # @param definition [String] the repo setup URI or RPM file
      # @param reponame [String] optional name of the repo, defaults to 'somerepo-md5'
      def yum_repo(definition, reponame = "somerepo" )
        # Add a semi-random suffix to the default in case more than one repo is specificied to use the default
        reponame = reponame + "-" +   Digest::MD5.hexdigest(definition)[0..6] if reponame == 'somerepo'
        self.provision_with "yum -y install curl"
        if ( definition =~ /^http/ and definition !~ /rpm$/ )
          # Repo definition is a URI e.g.
          # http://builds.puppetlabs.lan/puppet-agent/0.2.1/repo_configs/rpm/pl-puppet-agent-0.2.1-el-7-x86_64.repo
          reponame = reponame + '.repo'  if reponame !~ /\.repo$/
          self.provision_with "curl -o '/etc/yum.repos.d/#{reponame}' '#{definition}'"
        else ( definition =~ /rpm$/ )
          # repo definition is an rpm (like puppetlabs-release)
          self.provision_with "yum localinstall -y '#{definition}'"
        end
      end

    end
  end
end
