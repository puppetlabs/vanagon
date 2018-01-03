class Vanagon
  class Platform
    class RPM
      # This platform definition was created to account for oddities with
      # the RPM available on WindRiver Linux based systems. WRL uses RPMv5
      # and some of the WRL-based OS platforms we support (e.g, HuaweiOS)
      # do not have package repo systems or support for installing remote
      # RPMs via urls
      class WRL < Vanagon::Platform::RPM
        # Some WRL RPM platforms (e.g, HuaweiOS) don't allow you to
        # install remote packages via url, so we'll do a dance to
        # download them via curl and then perform the installs locally.
        # This method generates a shell script to be executed on the
        # system to do this.
        #
        # @param build_dependencies [Array] list of all build dependencies to install
        # @return [String] a command to install all of the build dependencies
        def install_build_dependencies(build_dependencies)
          commands = []
          unless build_dependencies.empty?
            commands << "tmpdir=$(#{mktemp})"
            commands << "cd ${tmpdir}"
            build_dependencies.each do |build_dependency|
              if build_dependency =~ /^http.*\.rpm$/
                # We're downloading each package individually so
                # failures are easier to troubleshoot
                commands << %(curl --remote-name --location --fail --silent #{build_dependency} && echo "Successfully downloaded #{build_dependency}")
              end
            end
            # Install the downloaded packages
            commands << "rpm -Uvh --nodeps --replacepkgs ${tmpdir}/*.rpm"
          end

          commands.join(' && ')
        end
      end
    end
  end
end
