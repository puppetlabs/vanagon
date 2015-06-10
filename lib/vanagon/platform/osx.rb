class Vanagon
  class Platform
    class OSX < Vanagon::Platform
      # The specific bits used to generate a osx package for a given project
      #
      # @param project [Vanagon::Project] project to build a osx package of
      # @return [Array] list of commands required to build a osx package for the given project from a tarball
      def generate_package(project)
        target_dir = project.repo ? output_dir(project.repo) : output_dir
         # Setup build directories
        ["bash -c 'mkdir -p $(tempdir)/osx/build/{pkg,scripts,resources,root,payload}'",
         "mkdir -p $(tempdir)/osx/build/root/#{project.name}-#{project.version}",
         # Grab distribution xml, scripts and other external resources
         "cp #{project.name}-installer.xml $(tempdir)/osx/build/",
         "cp scripts/* $(tempdir)/osx/build/scripts/",
         "if [ -d resources/osx/productbuild ] ; then cp resources/osx/productbuild/* $(tempdir)/osx/build/resources/; fi",
         # Unpack the project
         "gunzip -c #{project.name}-#{project.version}.tar.gz | '#{@tar}' -C '$(tempdir)/osx/build/root/#{project.name}-#{project.version}' --strip-components 1 -xf -",
         # Package the project
         "(cd $(tempdir)/osx/build/; #{@pkgbuild} --root root/#{project.name}-#{project.version} \
          --scripts $(tempdir)/osx/build/scripts \
          --identifier #{project.identifier}.#{project.name} \
          --version #{project.version} \
          --install-location / \
          payload/#{project.name}-#{project.version}.pkg)",
         # Create a custom installer using the pkg above and ship it to the output dir
         "(cd $(tempdir)/osx/build/; #{@productbuild} --distribution #{project.name}-installer.xml \
          --identifier #{project.identifier}.#{project.name}-installer \
          --package-path payload/ \
          --resources $(tempdir)/osx/build/resources  \
	  pkg/#{project.package_name})",
         "mkdir -p output/#{target_dir}",
         "cp $(tempdir)/osx/build/pkg/#{project.package_name} ./output/#{target_dir}"]
      end

      # Method to generate the files required to build a osx package for the project
      #
      # @param workdir [String] working directory to stage the evaluated templates in
      # @param name [String] name of the project
      # @param binding [Binding] binding to use in evaluating the packaging templates
      def generate_packaging_artifacts(workdir, name, binding)
        resources_dir = File.join(workdir, "resources", "osx")
        FileUtils.mkdir_p(resources_dir)
        script_dir = File.join(workdir, "scripts")
        FileUtils.mkdir_p(script_dir)

        erb_file(File.join(VANAGON_ROOT, "templates/osx/project-installer.xml.erb"), File.join(workdir, "#{name}-installer.xml"), false, {:binding => binding})

        ["postinstall", "preinstall"].each do |script_file|
          erb_file(File.join(VANAGON_ROOT, "templates/osx/#{script_file}.erb"), File.join(script_dir, script_file), false, {:binding => binding})
          FileUtils.chmod 0755, File.join(script_dir, script_file)
        end

        # Probably a better way to do this, but OSX tends to need some extra stuff
        FileUtils.cp_r("resources/osx/.", resources_dir) if File.exist?("resources/osx/")
      end

      # Method to derive the package name for the project
      #
      # @param project [Vanagon::Project] project to name
      # @return [String] name of the osx package for this project
      def package_name(project)
        "#{project.name}-#{project.version}-#{@os_name}-#{@os_version}-#{@architecture}.pkg"
      end

      # Get the expected output dir for the osx packages. This allows us to
      # use some standard tools to ship internally.
      #
      # @return [String] relative path to where osx packages should be staged
      def output_dir(target_repo = "")
        File.join("osx", target_repo)
      end

      # Constructor. Sets up some defaults for the osx platform and calls the parent constructor
      #
      # @param name [String] name of the platform
      # @return [Vanagon::Platform::OSX] the osx derived platform with the given name
      def initialize(name)
        @name = name
        @make = "/usr/bin/make"
        @tar = "tar"
        @pkgbuild = "/usr/bin/pkgbuild"
        @productbuild = "/usr/bin/productbuild"
        @hdiutil = "/usr/bin/hdiutil"
        @patch = "/usr/bin/patch"
        @num_cores = "/usr/sbin/sysctl -n hw.physicalcpu"
        super(name)
      end
    end
  end
end
