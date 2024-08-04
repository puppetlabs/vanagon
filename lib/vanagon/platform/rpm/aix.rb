class Vanagon
  class Platform
    class RPM
      # AIX is special. This subclassing gives us the chance to define some sane
      # defaults for aix without cluttering the main rpm class in if statements.
      class AIX < Vanagon::Platform::RPM
        def rpm_defines
          %(--define '_topdir $(tempdir)/rpmbuild' )
        end

        # Constructor. Sets up some defaults for the aix platform and calls the parent constructor
        #
        # @param name [String] name of the platform
        # @return [Vanagon::Platform::RPM::AIX] the rpm derived platform with the given name
        def initialize(name)
          @name = name
          @make = "/usr/bin/gmake"
          @tar = "/opt/freeware/bin/tar"
          @patch = "/opt/freeware/bin/patch"
          @sed = "/opt/freeware/bin/sed"
          @shasum = "/opt/freeware/bin/sha1sum"
          @num_cores = "lsdev -Cc processor |wc -l"
          @install = "/opt/freeware/bin/install"
          @rpmbuild = "/usr/bin/rpm"
          super
        end
      end
    end
  end
end
