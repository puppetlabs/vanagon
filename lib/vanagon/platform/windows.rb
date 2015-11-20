class Vanagon
  class Platform
    class Windows < Vanagon::Platform
      # The specific bits used to generate a windows package for a given project
      #
      # @param project [Vanagon::Project] project to build a windows package of
      # @return [Array] list of commands required to build a windows package for the given project from a tarball
      def generate_package(project)
        # If nothing is passed in as platform type, default to building a nuget package
        # We should default to building an MSI once that code has been implimented
        if project.platform.package_type.nil? || project.platform.package_type.empty?
          return generate_nuget_package(project)
        else
          case project.platform.package_type
          when "nuget", "nupkg"
            return generate_nuget_package(project)
          else
            raise Vanagon::Error "I don't know how to build package type '#{project.platform.package_type}' for Windows. Teach me?"
          end
        end
      end

      # Method to derive the package name for the project
      #
      # @param project [Vanagon::Project] project to name
      # @return [String] name of the windows package for this project
      def package_name(project)
        # If nothing is passed in as platform type, default to a nuget package
        # We should default to an MSI once that code has been implimented
        if project.platform.package_type.nil? || project.platform.package_type.empty?
          return nuget_package_name(project)
        else
          case project.platform.package_type
          when "nuget", "nupkg"
            return nuget_package_name(project)
          else
            raise Vanagon::Error "I don't know how to name package type '#{project.platform.package_type}' for Windows. Teach me?"
          end
        end
      end

      # Method to generate the files required to build a windows package for the project
      #
      # @param workdir [String] working directory to stage the evaluated templates in
      # @param name [String] name of the project
      # @param binding [Binding] binding to use in evaluating the packaging templates
      def generate_packaging_artifacts(workdir, name, binding)
        # templates that do require a name change
        erb_file(File.join(VANAGON_ROOT, "templates/windows/project.nuspec.erb"), File.join(workdir, "#{name}.nuspec"), false, { :binding => binding })

        # templates that don't require a name change
        ["chocolateyInstall.ps1", "chocolateyUninstall.ps1"].each do |win_file|
          erb_file(File.join(VANAGON_ROOT, "templates/windows/#{win_file}.erb"), File.join(workdir, win_file), false, { :binding => binding })
        end
      end

      # The specific bits used to generate a windows nuget package for a given project
      # Nexus expects packages to be named #{name}-#{version}.nupkg. However, chocolatey
      # will generate them to be #{name}.#{version}.nupkg. So, we have to rename the
      # package after we build it. We also take advantage of the rename to sneak the
      # architecture in the package name. Neither chocolatey nor nexus know how to deal
      # with architecture, so we are just pretending it's part of the package name.
      #
      # @param project [Vanagon::Project] project to build a nuget package of
      # @return [Array] list of commands required to build a nuget package for the given project from a tarball
      def generate_nuget_package(project)
        target_dir = project.repo ? output_dir(project.repo) : output_dir
        ["mkdir -p output/#{target_dir}",
        "mkdir -p $(tempdir)/#{project.name}/tools",
        "cp #{project.name}.nuspec $(tempdir)/#{project.name}/",
        "cp chocolateyInstall.ps1 chocolateyUninstall.ps1 $(tempdir)/#{project.name}/tools/",
        "cp file-list $(tempdir)/#{project.name}/tools/file-list.txt",
        "gunzip -c #{project.name}-#{project.version}.tar.gz | '#{@tar}' -C '$(tempdir)/#{project.name}/tools' --strip-components 1 -xf -",
        "(cd $(tempdir)/#{project.name} ; #{self.drive_root}/ProgramData/chocolatey/bin/choco.exe pack #{project.name}.nuspec)",
        "cp $(tempdir)/#{project.name}/#{project.name}-#{@architecture}.#{project.version}.#{project.release}.nupkg ./output/#{target_dir}/#{nuget_package_name(project)}"]
      end

      # Method to derive the package name for the project.
      # Nexus expects packages to be named #{name}-#{version}.nupkg. However, chocolatey
      # will generate them to be #{name}.#{version}.nupkg. So, we have to rename the
      # package after we build it. We also take advantage of the rename to sneak the
      # architecture in the package name. Neither chocolatey nor nexus know how to deal
      # with architecture, so we are just pretending it's part of the package name.
      #
      # @param project [Vanagon::Project] project to name
      # @return [String] name of the windows package for this project
      def nuget_package_name(project)
        "#{project.name}-#{@architecture}-#{project.version}.#{project.release}.nupkg"
      end

      # Add a repository (or install Chocolatey)
      # Note - this only prepares the list of commands to be executed once the Platform
      # has been setup
      #
      # @param definition [String] Definition for adding repo, can be a Repo URL (including file:)
      #    If file suffix is 'ps1' it is downloaded and executed to install chocolatey
      # @return [Array]  Commands to executed after platform startup
      def add_repository(definition)
        definition = URI.parse(definition)
        commands = []

        if definition.scheme =~ /^(http|ftp|file)/
          if File.extname(definition.path) == '.ps1'
            commands << %(powershell.exe -NoProfile -ExecutionPolicy Bypass -Command 'iex ((new-object net.webclient).DownloadString(\"#{definition}\"))')
          else
            commands << %(C:/ProgramData/chocolatey/bin/choco.exe source add -n #{definition.host}-#{definition.path.gsub('/', '-')} -s "#{definition}" --debug || echo "Oops, it seems that you don't have chocolatey installed on this system. Please ensure it's there by adding something like 'plat.add_repository 'https://chocolatey.org/install.ps1'' to your platform definition.")
          end
        else
          raise Vanagon::Error "Invalid repo specification #{definition}"
        end

        commands
      end

      # Get the expected output dir for the windows packages. This allows us to
      # use some standard tools to ship internally.
      #
      # @param target_repo [String] optional repo target for built packages defined
      #   at the project level
      # @return [String] relative path to where windows packages should be staged
      def output_dir(target_repo = "")
        File.join("windows", target_repo, @architecture)
      end

      # Return the drive root currently used on windows. At the moment, this is cygwin, but
      # may at some unknown date change to bitvise.
      #
      # @return [String] the cygwin drive root
      def drive_root
        "/cygdrive/c"
      end

      # Get the windows path equivelant using cygpath
      #
      # @param path [String] the path to convert to windows style pathing
      # @return [String] the windows style path for the given path
      def convert_to_windows_path(path)
        path.sub("/cygdrive/c", "C:")
      end

      # Constructor. Sets up some defaults for the windows platform and calls the parent constructor
      #
      # Mingw varies on where it is installed based on architecure. We want to use which ever is on the system.
      #
      # @param name [String] name of the platform
      # @return [Vanagon::Platform::DEB] the win derived platform with the given name
      def initialize(name)
        @target_user = "Administrator"
        @make = "(#{self.drive_root}/tools/mingw64/bin/mingw32-make || #{self.drive_root}/tools/mingw32/bin/mingw32-make)"
        @tar = "/usr/bin/tar"
        @find = "/usr/bin/find"
        @sort = "/usr/bin/sort"
        super(name)
      end
    end
  end
end
