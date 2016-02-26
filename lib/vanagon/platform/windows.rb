class Vanagon
  class Platform
    class Windows < Vanagon::Platform
      # The specific bits used to generate a windows package for a given project
      #
      # @param project [Vanagon::Project] project to build a windows package of
      # @return [Array] list of commands required to build a windows package for the given project from a tarball
      def generate_package(project)
        case project.platform.package_type
        when "msi"
          return generate_msi_package(project)
        when "nuget"
          return generate_nuget_package(project)
        else
          raise Vanagon::Error, "I don't know how to build package type '#{project.platform.package_type}' for Windows. Teach me?"
        end
      end

      # Method to derive the package name for the project
      #
      # @param project [Vanagon::Project] project to name
      # @return [String] name of the windows package for this project
      def package_name(project)
        case project.platform.package_type
        when "msi"
          return msi_package_name(project)
        when "nuget"
          return nuget_package_name(project)
        else
          raise Vanagon::Error, "I don't know how to name package type '#{project.platform.package_type}' for Windows. Teach me?"
        end
      end

      # Method to generate the files required to build a windows package for the project
      #
      # @param workdir [String] working directory to stage the evaluated templates in
      # @param name [String] name of the project
      # @param binding [Binding] binding to use in evaluating the packaging templates
      def generate_packaging_artifacts(workdir, name, binding)
        case @package_type
        when "msi"
          return generate_msi_packaging_artifacts(workdir, name, binding)
        when "nuget"
          return generate_nuget_packaging_artifacts(workdir, name, binding)
        else
          raise Vanagon::Error, "I don't know how create packaging artifacts for package type '#{project.platform.package_type}' for Windows. Teach me?"
        end
      end

      # Method to generate the files required to build an MSI  package for the project
      #
      # @param workdir [String] working directory to stage the evaluated templates in
      # @param name [String] name of the project
      # @param binding [Binding] binding to use in evaluating the packaging templates
      def generate_msi_packaging_artifacts(workdir, name, binding)
        FileUtils.mkdir_p(File.join(workdir, "wix"))
        erb_file(File.join(VANAGON_ROOT, "resources/windows/wix/project.wxs.erb"), File.join(workdir, "wix",  "#{name}.wxs"), false, { :binding => binding })
        erb_file(File.join(VANAGON_ROOT, "resources/windows/wix/project.filter.xslt.erb"), File.join(workdir, "wix", "#{name}.filter.xslt"), false, { :binding => binding })
        erb_file(File.join(VANAGON_ROOT, "resources/windows/wix/directorylist.wxs.erb"), File.join(workdir, "wix", "directorylist.#{name}.wxs"), false, { :binding => binding })
      end

      # Method to generate the files required to build a nuget package for the project
      #
      # @param workdir [String] working directory to stage the evaluated templates in
      # @param name [String] name of the project
      # @param binding [Binding] binding to use in evaluating the packaging templates
      def generate_nuget_packaging_artifacts(workdir, name, binding)
        # nuget templates that do require a name change
        erb_file(File.join(VANAGON_ROOT, "resources/windows/nuget/project.nuspec.erb"), File.join(workdir, "#{name}.nuspec"), false, { :binding => binding })

        # nuget static resources to be copied into place
        ["chocolateyInstall.ps1", "chocolateyUninstall.ps1"].each do |win_file|
          FileUtils.copy(File.join(VANAGON_ROOT, "resources/windows/nuget/#{win_file}"), File.join(workdir, win_file))
        end
      end

      # The specific bits used to generate a windows nuget package for a given project
      # Nexus expects packages to be named #{name}-#{version}.nupkg. However, chocolatey
      # will generate them to be #{name}.#{version}.nupkg. So, we have to rename the
      # package after we build it.
      #
      # @param project [Vanagon::Project] project to build a nuget package of
      # @return [Array] list of commands required to build a nuget package for
      # the given project from a tarball
      def generate_nuget_package(project)
        target_dir = project.repo ? output_dir(project.repo) : output_dir
        ["mkdir -p output/#{target_dir}",
        "mkdir -p $(tempdir)/#{project.name}/tools",
        "#{@copy} #{project.name}.nuspec $(tempdir)/#{project.name}/",
        "#{@copy} chocolateyInstall.ps1 chocolateyUninstall.ps1 $(tempdir)/#{project.name}/tools/",
        "#{@copy} file-list $(tempdir)/#{project.name}/tools/file-list.txt",
        "gunzip -c #{project.name}-#{project.version}.tar.gz | '#{@tar}' -C '$(tempdir)/#{project.name}/tools' --strip-components 1 -xf -",
        "(cd $(tempdir)/#{project.name} ; C:/ProgramData/chocolatey/bin/choco.exe pack #{project.name}.nuspec)",
        "#{@copy} $(tempdir)/#{project.name}/#{project.name}-#{@architecture}.#{nuget_package_version(project.version, project.release)}.nupkg ./output/#{target_dir}/#{nuget_package_name(project)}"]
      end

      # The specific bits used to generate a windows msi package for a given project
      # Have changed this to reflect the overall commands we need to generate the package.
      # Question - should we break this down into some simpler Make tasks ?
      # 1. Heat the directory tree to produce the file list
      # 2. Compile (candle) all the wxs files into wixobj files
      # 3. Run light to produce the final MSI
      #
      # @param project [Vanagon::Project] project to build a msi package of
      # @return [Array] list of commands required to build an msi package for the given project from a tarball
      def generate_msi_package(project)
        target_dir = project.repo ? output_dir(project.repo) : output_dir
        cg_name = "ProductComponentGroup"
        dir_ref = "INSTALLDIR"
        wix_extensions =  "-ext WiXUtilExtension -ext WixUIExtension"
        candle_flags =  "-dPlatform=#{@architecture} -arch #{@architecture} #{wix_extensions}"
        # Enable verbose mode for the moment (will be removed for production)
        # localisation flags to be added
        light_flags = "-v -cultures:en-us #{wix_extensions}"
        # Actual array of commands to be written to the Makefile
        ["mkdir -p output/#{target_dir}",
          "mkdir -p $(tempdir)/{staging,wix/wixobj}",
          "#{@copy} -r wix/* $(tempdir)/wix/",
          "gunzip -c #{project.name}-#{project.version}.tar.gz | '#{@tar}' -C '$(tempdir)/staging' --strip-components 1 -xf -",
          # Run the Heat command in a single pass
          # Heat command documentation at: http://wixtoolset.org/documentation/manual/v3/overview/heat.html
          #   dir <directory> - Traverse directory to find all sub-files and directories.
          #   -ke             - Keep Empty directories
          #   -cg             - Component Group Name
          #   -gg             - Generate GUIDS now
          #   -dr             - Directory reference to root directories (cannot contains spaces e.g. -dr MyAppDirRef)
          #   -sreg           - Suppress registry harvesting.
          "cd $(tempdir); \"$$WIX/bin/heat.exe\" dir staging -v -ke -indent 2 -cg #{cg_name} -gg -dr #{dir_ref} -t wix/#{project.name}.filter.xslt -sreg -out wix/#{project.name}-harvest.wxs",
          # Apply Candle command to all *.wxs files - generates .wixobj files in wix directory.
          # cygpath conversion is necessary as candle is unable to handle posix path specs
          "cd $(tempdir)/wix/wixobj; for wix_file in `find $(tempdir)/wix -name \'*.wxs\'`; do \"$$WIX/bin/candle.exe\" #{candle_flags} $$(cygpath -aw $$wix_file) ; done",
          # run all wix objects through light to produce the msi
          "cd $(tempdir)/wix/wixobj; \"$$WIX/bin/light.exe\" #{light_flags} -out $$(cygpath -aw $(workdir)/output/#{target_dir}/#{msi_package_name(project)}) *.wixobj",
          ]
      end

      # Method to derive the msi (Windows Installer) package name for the project.
      #
      # @param project [Vanagon::Project] project to name
      # @return [String] name of the windows package for this project
      def msi_package_name(project)
        # Decided to use native project version in hope msi versioning doesn't have same resrictions as nuget
        "#{project.name}-#{project.version}.#{project.release}-#{@architecture}.msi"
      end

      # Method to derive the package name for the project.
      # Neither chocolatey nor nexus know how to deal with architecture, so
      # we are just pretending it's part of the package name.
      #
      # @param project [Vanagon::Project] project to name
      # @return [String] name of the windows package for this project
      def nuget_package_name(project)
        "#{project.name}-#{@architecture}-#{nuget_package_version(project.version, project.release)}.nupkg"
      end

      # Nuget versioning is awesome!
      #
      # Nuget and chocolatey have some expectations about version numbers.
      #
      # First, if this is a final package (built from a tag), the version must
      # only contain digits with each element of the version separated by
      # periods.
      #
      # If we are creating the version for a prerelease package (built from a
      # commit that does not have a corresponding tag), we have the
      # option to append a string to the version. The string must start with a
      # letter, be separated from the rest of the version with a dash, and
      # contain no punctuation.
      #
      # We assume we are working from a semver tag as the base of our version.
      # If this is a final release, we only have to worry about that tag. We
      # can also include the release number in the package version. If this is
      # a prerelease package, then we assume we have a semver compliant tag,
      # followed by the number of commits beyond the tag and the short sha of
      # the latest change. Because we are working with git, if the version
      # contains a short sha, it will begin with 'g'. We check for this to
      # determine what version type to deliver.
      #
      # Examples of final versions:
      #   1.2.3
      #   1.5.3.1
      #
      # Examples of prerelease versions:
      #   1.2.3.1234-g124dm9302
      #   3.2.5.23-gd329nd
      #
      # @param project [Vanagon::Project] project to version
      # @return [String] the version of the nuget package for this project
      def nuget_package_version(version, release)
        version_elements = version.split('.')
        if version_elements.last.start_with?('g')
          # Version for the prerelease package
          "#{version_elements[0..-2].join('.').gsub(/[a-zA-Z]/, '')}-#{version_elements[-1]}"
        else
          "#{version}.#{release}".gsub(/[a-zA-Z]/, '')
        end
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
          raise Vanagon::Error, "Invalid repo specification #{definition}"
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

      # Generate correctly formatted wix elements that match the
      # structure of the directory input
      #
      # @param directories, Array of hashes including at least :path
      # and optionally:
      # @return [string] correctly formatted wix element string
      def generate_wix_dirs(project)
        if project.get_directories.empty?
          raise Vanagon::Error, 'ERROR No directories specified!'
        else
          directories = []
          project.get_directories.map { |dir| directories.push({ :path => dir.path, :id => dir.wix_id }) }

          root = { :children => [] }

          # iterate over all paths specified and break each one
          # in to its specific directories. This will generate_wix_dirs
          # an n-ary tree structure matching the specs from the input
          directories.each do |dir|
            # Always start at the beginning
            curr = root
            names = strip_path(dir[:path])
            names.each do |name|
              #The Id field will default to name, but be overridden later
              new_obj = { :name => name, :id => name, :children => [] }
              if (child_index = includes_child(new_obj, curr[:children]))
                curr = curr[:children][child_index]
              else
                curr[:children].push(new_obj)
                curr = new_obj
              end
            end
            # at this point, curr will be the top dir, override the id if
            # id exists
            if dir[:id]
              curr[:id] = dir[:id]
            end
          end
          return generate_wix_from_graph(root)
        end
      end

      # strip and split the directory path into single names
      # @param [string] path string of directory
      def strip_path(path)
        if path.include?("/") || path.include?("\\")
          # The regex in the last part of this if warrants some
          # explanation. Specifically it matches any combinations
          # of any letters, then the : char, then finally either
          # the char / or the char \. it's menat to parse out drive
          # roots on windows
          if path.start_with?("/") || path.start_with?("\\") || path =~ (/([A-Za-z])*\:(\/|\\)/)
            path = path.sub(/\/|\\|([A-Za-z])*\:(\/|\\)/, '')
          end
          names = path.split(/\/|\\/)
        end
        return names
      end

      # Find if child element is the same as one of
      # the old_children elements, return that child
      def includes_child(new_child, old_children)
        old_children.each_with_index do |curr_old_child, index|
          return index if curr_old_child[:name] == new_child[:name]
        end unless old_children.empty?
        return nil
      end

      # Recursively generate wix element structure
      #
      # @param root, the (empty) root of an n-ary tree containing the
      # structure of directories
      def generate_wix_from_graph(root)
        string = ''
        unless root[:children].empty?
          root[:children].each do |child|
            string += ("<Directory Name=\"#{child[:name]}\" Id=\"#{child[:id]}\">\n")
            string += generate_wix_from_graph(child)
            string += ("</Directory>\n")
          end
          return string
        end
        return ''
      end

      # Constructor. Sets up some defaults for the windows platform and calls the parent constructor
      #
      # Mingw varies on where it is installed based on architecture. We want to use which ever is on the system.
      #
      # @param name [String] name of the platform
      # @return [Vanagon::Platform::Windows] the win derived platform with the given name
      def initialize(name)
        @target_user = "Administrator"
        @make = "/usr/bin/make"
        @tar = "/usr/bin/tar"
        @find = "/usr/bin/find"
        @sort = "/usr/bin/sort"
        @num_cores = "/usr/bin/nproc"
        @install = "/usr/bin/install"
        @copy = "/usr/bin/cp"
        @package_type = "msi"
        super(name)
      end
    end
  end
end
