class Vanagon
  class Platform
    class OSX < Vanagon::Platform
      # Because homebrew does not support being run by root
      # we need to have this method to run it in the context of another user
      #
      # @param build_dependencies [Array] list of all build dependencies to install
      # @return [String] a command to install all of the build dependencies
      def install_build_dependencies(list_build_dependencies)
        <<-HERE.undent
          mkdir -p /etc/homebrew
          cd /etc/homebrew
          su test -c '/usr/local/bin/brew install #{list_build_dependencies.join(' ')}'
        HERE
      end

      # The specific bits used to generate a osx package for a given project
      #
      # @param project [Vanagon::Project] project to build a osx package of
      # @return [Array] list of commands required to build a osx package for the given project from a tarball
      def generate_package(project) # rubocop:disable Metrics/AbcSize
        target_dir = project.repo ? output_dir(project.repo) : output_dir

        # Here we maintain backward compatibility with older vanagon versions
        # that did this by default.  This shim should get removed at some point
        # in favor of just letting the makefile deliver the bill-of-materials
        # to the correct directory. This shouldn't be required at all then.
        if project.bill_of_materials.nil?
          bom_install = [
            # Move bill-of-materials into a docdir
            "mkdir -p $(tempdir)/osx/build/root/#{project.name}-#{project.version}/usr/local/share/doc/#{project.name}",
            "mv $(tempdir)/osx/build/root/#{project.name}-#{project.version}/bill-of-materials $(tempdir)/osx/build/root/#{project.name}-#{project.version}/usr/local/share/doc/#{project.name}/bill-of-materials",
          ]
        else
          bom_install = []
        end

        if project.extra_files_to_sign.any?
          sign_commands = Vanagon::Utilities::ExtraFilesSigner.commands(project, @mktemp, "/osx/build/root/#{project.name}-#{project.version}")
        else
          sign_commands = []
        end

        signing_host = "jenkins@osx-signer-prod-2.delivery.puppetlabs.net"

         # Setup build directories
        ["bash -c 'mkdir -p $(tempdir)/osx/build/{dmg,pkg,scripts,resources,root,payload,plugins}'",
         "mkdir -p $(tempdir)/osx/build/root/#{project.name}-#{project.version}",
         "mkdir -p $(tempdir)/osx/build/pkg",
         # Grab distribution xml, scripts and other external resources
         "cp #{project.name}-installer.xml $(tempdir)/osx/build/",
         #copy the uninstaller to the pkg dir, where eventually the installer will go too
         "cp #{project.name}-uninstaller.tool $(tempdir)/osx/build/pkg/",
         "cp scripts/* $(tempdir)/osx/build/scripts/",
         "if [ -d resources/osx/productbuild ] ; then cp -r resources/osx/productbuild/* $(tempdir)/osx/build/; fi",
         # Unpack the project
         "gunzip -c #{project.name}-#{project.version}.tar.gz | '#{@tar}' -C '$(tempdir)/osx/build/root/#{project.name}-#{project.version}' --strip-components 1 -xf -",

         bom_install,

         #  The signing commands below should not cause `vanagon build` to fail. Many devs need to run `vanagon build`
         #  locally and do not necessarily need signed packages. The `|| :` will rescue failures by evaluating as successful.
         #  /Users/binaries will be a list of all binaries that need to be signed
         "touch /Users/binaries || :",
         #  Find all of the executables (Mach-O files), and put the in /Users/binaries
         "echo bananaa",
         "for item in `find $(tempdir)/osx/build/ -perm -0100 -type f` ; do file $$item | grep 'Mach-O' ; done | awk '{print $$1}' | sed 's/\:$$//' > /Users/binaries || :",
         #  A tmpdir is created on the signing_host, all off the executables will be rsyncd there to be signed
         "echo dog",
         "#{Vanagon::Utilities.ssh_command}  #{signing_host} mkdir -p /tmp/$(binaries_dir) || :",
         "echo apple",
         "rsync -e '#{Vanagon::Utilities.ssh_command}' --no-perms --no-owner --no-group --files-from=/Users/binaries / #{signing_host}:/tmp/$(binaries_dir) || :",
         "echo raisin",
         "rsync -e '#{Vanagon::Utilities.ssh_command}' --no-perms --no-owner --no-group /Users/binaries #{signing_host}:/tmp/binaries_list || :",
         #  The binaries are signed, and then rsynced back
         "#{Vanagon::Utilities.ssh_command}  #{signing_host} /usr/local/bin/sign.sh $(binaries_dir) || :",
         "echo peach",
         "rsync -e '#{Vanagon::Utilities.ssh_command}' --no-perms --no-owner --no-group -r #{signing_host}:/tmp/$(binaries_dir)/var/ /var || :",
         "echo parsnip",

         # Sign extra files
         sign_commands,
         # Some extra files are created during the signing process that are not needed, so we delete them! Otherwise 
         # notarization gets confused by these extra files. 
          "for item in `find $(tempdir)/osx/build -type d -name Resources` ; do rm -rf $$item ; done || :",


         # Package the project
         "(cd $(tempdir)/osx/build/; #{@pkgbuild} --root root/#{project.name}-#{project.version} \
          --scripts $(tempdir)/osx/build/scripts \
          --identifier #{project.identifier}.#{project.name} \
          --version #{project.version} \
          --preserve-xattr \
          --install-location / \
          payload/#{project.name}-#{project.version}-#{project.release}.pkg)",
         # Create a custom installer using the pkg above
         "(cd $(tempdir)/osx/build/; #{@productbuild} --distribution #{project.name}-installer.xml \
          --identifier #{project.identifier}.#{project.name}-installer \
          --package-path payload/ \
          --resources $(tempdir)/osx/build/resources  \
          --plugins $(tempdir)/osx/build/plugins  \
          pkg/#{project.name}-#{project.version}-#{project.release}-installer.pkg)",
         # Create a dmg and ship it to the output directory
         "(cd $(tempdir)/osx/build; \
           #{@hdiutil} create \
            -volname #{project.name}-#{project.version} \
            -fs JHFS+ \
            -format UDBZ \
            -srcfolder pkg \
            dmg/#{project.package_name})",
         "mkdir -p output/#{target_dir}",
         "cp $(tempdir)/osx/build/dmg/#{project.package_name} ./output/#{target_dir}"].flatten.compact
      end

      # Method to generate the files required to build a osx package for the project
      #
      # @param workdir [String] working directory to stage the evaluated templates in
      # @param name [String] name of the project
      # @param binding [Binding] binding to use in evaluating the packaging templates
      # @param project [Vanagon::Project] Vanagon::Project we are building for
      def generate_packaging_artifacts(workdir, name, binding, project) # rubocop:disable Metrics/AbcSize
        resources_dir = File.join(workdir, "resources", "osx")
        FileUtils.mkdir_p(resources_dir)
        script_dir = File.join(workdir, "scripts")
        FileUtils.mkdir_p(script_dir)

        erb_file(File.join(VANAGON_ROOT, "resources/osx/project-installer.xml.erb"), File.join(workdir, "#{name}-installer.xml"), false, { :binding => binding })

        ["postinstall", "preinstall"].each do |script_file|
          erb_file(File.join(VANAGON_ROOT, "resources/osx/#{script_file}.erb"), File.join(script_dir, script_file), false, { :binding => binding })
          FileUtils.chmod 0755, File.join(script_dir, script_file)
        end

        erb_file(File.join(VANAGON_ROOT, 'resources', 'osx', 'uninstaller.tool.erb'), File.join(workdir, "#{name}-uninstaller.tool"), false, { :binding => binding })
        FileUtils.chmod 0755, File.join(workdir, "#{name}-uninstaller.tool")

        # Probably a better way to do this, but OSX tends to need some extra stuff
        FileUtils.cp_r("resources/osx/.", resources_dir) if File.exist?("resources/osx/")
      end

      # Method to derive the package name for the project
      #
      # @param project [Vanagon::Project] project to name
      # @return [String] name of the osx package for this project
      def package_name(project)
        "#{project.name}-#{project.version}-#{project.release}.#{@os_name}#{@os_version}.dmg"
      end

      # Constructor. Sets up some defaults for the osx platform and calls the parent constructor
      #
      # @param name [String] name of the platform
      # @return [Vanagon::Platform::OSX] the osx derived platform with the given name
      def initialize(name)
        @name = name
        @make = "/usr/bin/make"
        @tar = "tar"
        @shasum = "/usr/bin/shasum"
        @pkgbuild = "/usr/bin/pkgbuild"
        @productbuild = "/usr/bin/productbuild"
        @hdiutil = "/usr/bin/hdiutil"
        @patch = "/usr/bin/patch"
        @num_cores = "/usr/sbin/sysctl -n hw.physicalcpu"
        @mktemp = "mktemp -d -t 'tmp'"
        super(name)
      end
    end
  end
end
