class Vanagon
  class Platform
    class RPM
      # SLES is special, mainly in the differences between yum and zypper,
      # so here we subclass SLES off of rpm.
      class SLES < Vanagon::Platform::RPM
        # Helper to setup a zypper repository on a target system
        #
        # @param definition [String] the repo setup URI or RPM file
        # @return [Array] A list of commands to add a zypper repo for the build system
        def add_repository(definition)
          definition = URI.parse(definition)
          if @os_version == '10'
            flag = 'sa'
          else
            flag = 'ar'
          end

          commands = []

          if definition.scheme =~ /^(http|ftp)/
            if File.extname(definition.path) == '.rpm'
              # repo definition is an rpm (like puppetlabs-release)
              commands << "curl -o local.rpm '#{definition}'; rpm -Uvh local.rpm; rm -f local.rpm"
            else
              commands << "yes | zypper -n --no-gpg-checks #{flag} -t YUM --repo '#{definition}'"
            end
          end

          commands
        end
      end
    end
  end
end
