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
        when "archive"
          # We don't need to generate the package for archives, return an
          # empty array
          return []
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
        when "archive"
          return "#{project.name}-#{project.version}-archive"
        else
          raise Vanagon::Error, "I don't know how to name package type '#{project.platform.package_type}' for Windows. Teach me?"
        end
      end

      # Method to generate the files required to build a windows package for the project
      #
      # @param workdir [String] working directory to stage the evaluated templates in
      # @param name [String] name of the project
      # @param binding [Binding] binding to use in evaluating the packaging templates
      # @param project [Vanagon::Project] Vanagon::Project we are building for
      def generate_packaging_artifacts(workdir, name, binding, project)
        case @package_type
        when "msi"
          return generate_msi_packaging_artifacts(workdir, name, binding)
        when "nuget"
          return generate_nuget_packaging_artifacts(workdir, name, binding)
        when "archive"
          # We don't need to generate packaging artifacts if this is an archive
          return
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
        # Copy the project specific files first
        copy_from_project("./resources/windows/wix", workdir)
        merge_defaults_from_vanagon(File.join(VANAGON_ROOT, "resources/windows/wix"), "#{workdir}/wix")
        process_templates("#{workdir}/wix", binding)
      end

      # Method to recursively copy from a source project resource directory
      # to a destination (wix) work directory.
      # strongly suspect the original cp_r command would have done all of this.
      #
      # @param proj_resources [String] Project Resource File directory
      # @param destination [String] Destination directory
      # @param verbose [String] True or false
      def copy_from_project(proj_resources, destination, verbose: false)
        FileUtils.cp_r(proj_resources, destination, :verbose => verbose)
      end

      # Method to merge in the files from the Vanagon (generic) directories.
      # Project Specific files take precedence, so since these are copied prior
      # to this function, then this merge operation will ignore existing files
      #
      # @param vanagon_root [String] Vanagon wix resources directory
      # @param destination [String] Destination directory
      # @param verbose [String] True or false
      def merge_defaults_from_vanagon(vanagon_root, destination, verbose: false) # rubocop:disable Metrics/AbcSize
        # Will use this Pathname object for relative path calculations in loop below.
        vanagon_path = Pathname.new(vanagon_root)
        files = Dir.glob(File.join(vanagon_root, "**/*.*"))
        files.each do |file|
          # Get Pathname for incoming file using Pathname library
          src_pathname = Pathname.new(file).dirname
          # This Pathname method allows us to effectively "subtract" the leading vanagon_path
          # from the source filename path. This gives us a pathname fragment that we can
          # then append to the target directory, preserving the files place in the directory
          # tree relative to the parent.
          # See following article for example:
          # http://stackoverflow.com/questions/12093770/ruby-removing-parts-a-file-path
          # and http://ruby-doc.org/stdlib-2.1.0/libdoc/pathname/rdoc/Pathname.html#method-i-relative_path_from
          dest_pathname_fragment = src_pathname.relative_path_from(vanagon_path)
          target_dir = File.join(destination, dest_pathname_fragment.to_s)
          # Create the target directory if necessary.
          FileUtils.mkdir_p(target_dir) unless File.exists?(target_dir)
          # Skip the file copy if either target file or ERB equivalent exists.
          # This means that any files already in place in the work directory as a
          # result of being copied from the project specific area will not be
          # overritten.
          next if File.exists?(Pathname.new(target_dir) + File.basename(file))
          next if File.exists?(Pathname.new(target_dir) + File.basename(file, ".erb"))
          FileUtils.cp(file, target_dir, :verbose => verbose)
        end
      end

      # Method to transform ERB templates in the work directory.
      #
      # @param workdir [String] working directory to stage the evaluated templates in
      # @param binding [Binding] binding to use in evaluating the packaging templates
      def process_templates(wixworkdir, binding)
        files = Dir.glob(File.join(wixworkdir, "**/*.erb"))
        files.each do |file|
          erb_file(file, File.join(File.dirname(file), File.basename(file, ".erb")), false, { :binding => binding })
          FileUtils.rm(file)
        end
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
      def generate_nuget_package(project) # rubocop:disable Metrics/AbcSize
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
      def generate_msi_package(project) # rubocop:disable Metrics/AbcSize
        target_dir = project.repo ? output_dir(project.repo) : output_dir
        wix_extensions = "-ext WiXUtilExtension -ext WixUIExtension"
        # Heat command documentation at: http://wixtoolset.org/documentation/manual/v3/overview/heat.html
        #   dir <directory> - Traverse directory to find all sub-files and directories.
        #   -ke             - Keep Empty directories
        #   -cg             - Component Group Name
        #   -gg             - Generate GUIDS now
        #   -srd            - Suppress root element generation, we want to reference one of the default root elements
        #                     INSTALLDIR or APPDATADIR in the directorylist.wxs file, not a newly generated one.
        #   -sreg           - Suppress registry harvesting.
        #   -dr             - Root DirectoryRef to point all components to
        #   -var            - Replace "SourceDir" in the @source attributes of all components with a preprocessor variable
        app_heat_flags = " -dr INSTALLDIR -v -ke -indent 2 -cg AppComponentGroup -gg -srd -t wix/filter.xslt -sreg -var var.AppSourcePath "
        app_source_path = "SourceDir/#{project.settings[:base_dir]}/#{project.settings[:company_id]}/#{project.settings[:product_id]}"
        # Candle.exe preprocessor vars are required due to the above double run of heat.exe, both runs of heat use
        # preprocessor variables
        candle_preprocessor = "-dAppSourcePath=\"#{app_source_path}\" "
        candle_flags = "-arch #{@architecture} #{wix_extensions}"
        # Enable verbose mode for the moment (will be removed for production)
        # localisation flags to be added
        light_flags = "-v -cultures:en-us #{wix_extensions}"
        # "Misc Dir for versions.txt, License file and Icon file"
        misc_dir = "SourceDir/#{project.settings[:base_dir]}/#{project.settings[:company_id]}/#{project.settings[:product_id]}/misc"
        # Actual array of commands to be written to the Makefile
        [
          "mkdir -p output/#{target_dir}",
          "mkdir -p $(tempdir)/{SourceDir,wix/wixobj}",
          "#{@copy} -r wix/* $(tempdir)/wix/",
          "gunzip -c #{project.name}-#{project.version}.tar.gz | '#{@tar}' -C '$(tempdir)/SourceDir' --strip-components 1 -xf -",
          "mkdir -p $(tempdir)/#{misc_dir}",
          # Need to use awk here to convert to DOS format so that notepad can display file correctly.
          "awk 'sub(\"$$\", \"\\r\")' $(tempdir)/SourceDir/bill-of-materials > $(tempdir)/#{misc_dir}/versions.txt",
          "cd $(tempdir); \"$$WIX/bin/heat.exe\" dir #{app_source_path} #{app_heat_flags} -out wix/#{project.name}-harvest-app.wxs",

          # Apply Candle command to all *.wxs files - generates .wixobj files in wix directory.
          # cygpath conversion is necessary as candle is unable to handle posix path specs
          # the preprocessor variables AppDataSourcePath and ApplicationSourcePath are required due to the -var input to the heat
          # runs listed above.
          "cd $(tempdir)/wix/wixobj; for wix_file in `find $(tempdir)/wix -name \'*.wxs\'`; do \"$$WIX/bin/candle.exe\" #{candle_flags} #{candle_preprocessor} $$(cygpath -aw $$wix_file) || exit 1; done",
          # run all wix objects through light to produce the msi
          # the -b flag simply points light to where the SourceDir location is
          # -loc is required for the UI localization it points to the actual localization .wxl
          "cd $(tempdir)/wix/wixobj; \"$$WIX/bin/light.exe\" #{light_flags} -b $$(cygpath -aw $(tempdir)) -loc $$(cygpath -aw $(tempdir)/wix/localization/puppet_en-us.wxl) -out $$(cygpath -aw $(workdir)/output/#{target_dir}/#{msi_package_name(project)}) *.wixobj",
        ]
      end

      # Method to derive the msi (Windows Installer) package name for the project.
      #
      # @param project [Vanagon::Project] project to name
      # @return [String] name of the windows package for this project
      def msi_package_name(project)
        # Decided to use native project version in hope msi versioning doesn't have same resrictions as nuget
        "#{project.name}-#{project.version}-#{@architecture}.msi"
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
            commands << %(C:/ProgramData/chocolatey/bin/choco.exe source add -n #{definition.host}-#{definition.path.tr('/', '-')} -s "#{definition}" --debug || echo "Oops, it seems that you don't have chocolatey installed on this system. Please ensure it's there by adding something like 'plat.add_repository 'https://chocolatey.org/install.ps1'' to your platform definition.")
          end
        else
          raise Vanagon::Error, "Invalid repo specification #{definition}"
        end

        commands
      end

      # Generate the underlying directory structure of
      # any binary files referenced in services. note that
      # this function does not generate the structure of
      # the installation directory, only the structure above it.
      #
      # @param services, list of all services in a project
      # @param project, actual project we are creating the directory structure for
      def generate_service_bin_dirs(services, project)
        # All service files will need a directory reference
        items = services.map do |svc|
          {
            :path => strip_and_format_path(svc.service_file, project),
            :element_to_add => "<Directory Id=\"#{svc.bindir_id}\" />\n"
          }
        end
        generate_wix_dirs(items)
      end

      # Generate correctly formatted wix elements that match the
      # structure of the itemized input
      #
      # @param items
      # @return [string] correctly formatted wix element string
      def generate_wix_dirs(items)
        # root refers to the root of an n-ary tree (which we are about to make)
        root = { :children => [] }
        # iterate over all paths specified and break each one
        # in to its specific directories. This will generate_wix_dirs
        # an n-ary tree structure matching the specs from the input
        items.each_with_index do |item, item_idx|
          # Always start at the beginning
          curr = root
          names = item[:path].split(File::SEPARATOR)
          names.each_with_index do |name, names_idx|
            # We concat the indexes of each loop to name to ensure the ids of all
            # elements will be unique.
            curr = insert_child(curr, name, "#{name}_#{item_idx}_#{names_idx}")
          end
          # at this point, curr will be the top dir, override the id if
          # id exists
          curr[:elements_to_add].push(item[:element_to_add])
        end
        generate_wix_from_graph(root)
      end

      # insert a new object with the name "name" if it doesn't already
      # exist. Then assign curr to either the new child or the one that
      # already exists here
      #
      # @param [HASH] curr, current object we are on
      # @param [string] name, name of new object we are to search for and
      #                 create if necessary
      def insert_child(curr, name, id)
        #The Id field will default to name, but be overridden later
        new_obj = { :name => name, :id => id, :elements_to_add => [], :children => [] }
        if (child_index = index_of_child(new_obj, curr[:children]))
          curr = curr[:children][child_index]
        else
          curr[:children].push(new_obj)
          curr = new_obj
        end
        curr
      end

      # strip the leading install root and the filename from the service path
      # and replace any \ with /
      #
      # @param [string] path string of directory
      # @param [@project] project object
      def strip_and_format_path(path, project)
        formatted_path = path.tr('\\', '\/')
        path_regex = /\/?SourceDir\/#{project.settings[:base_dir]}\/#{project.settings[:company_id]}\/#{project.settings[:product_id]}\//
        File.dirname(formatted_path.sub(path_regex, ''))
      end

      # Find if child element is the same as one of
      # the old_children elements, return that child
      def index_of_child(new_child, old_children)
        return nil if old_children.empty?
        old_children.index { |child| child[:name] == new_child[:name] }
      end

      # Recursively generate wix element structure
      #
      # @param root, the (empty) root of an n-ary tree containing the
      # structure of directories
      def generate_wix_from_graph(root)
        string = ''
        unless root[:children].empty?
          root[:children].each do |child|
            string += "<Directory Name=\"#{child[:name]}\" Id=\"#{child[:id]}\">\n"
            unless child[:elements_to_add].empty?
              child[:elements_to_add].each do |element|
                string += element
              end
            end
            string += generate_wix_from_graph(child)
            string += "</Directory>\n"
          end
          return string
        end
        string
      end

      # Grab only the first three values from the version input
      # and strip off any non-digit characters.\
      #
      # @param [string] version, the original version number
      def wix_product_version(version)
        version.split("\.").first(3).collect { |value| value.gsub(/[^0-9]/, '') }.join("\.")
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
