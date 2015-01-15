class Vanagon
  class Platform
    class DEB < Vanagon::Platform
      # The specific bits used to generate a debian package for a given project
      #
      # @param project [Vanagon::Project] project to build a debian package of
      # @return [Array] list of commands required to build a debian package for the given project from a tarball
      def generate_package(project)
        ["mkdir -p output/#{output_dir}",
        "mkdir -p $(tempdir)/#{project.name}-#{project.version}",
        "cp #{project.name}-#{project.version}.tar.gz $(tempdir)/#{project.name}_#{project.version}.orig.tar.gz",
        "cp -pr debian $(tempdir)/#{project.name}-#{project.version}",
        "gunzip -c #{project.name}-#{project.version}.tar.gz | tar -C '$(tempdir)/#{project.name}-#{project.version}' --strip-components 1 -xf -",
        "(cd $(tempdir)/#{project.name}-#{project.version}; debuild --no-lintian -uc -us)",
        "cp $(tempdir)/*.deb ./output/#{output_dir}"]
      end

      # Method to generate the files required to build a debian package for the project
      #
      # @param workdir [String] working directory to stage the evaluated templates in
      # @param name [String] name of the project
      # @param binding [Binding] binding to use in evaluating the packaging templates
      def generate_packaging_artifacts(workdir, name, binding)
        deb_dir = File.join(workdir, "debian")
        FileUtils.mkdir_p(deb_dir)

        # Lots of templates here
        ["changelog", "conffiles", "control", "dirs", "install", "postinst", "postrm", "prerm", "rules"].each do |deb_file|
          erb_file(File.join(VANAGON_ROOT, "templates/#{deb_file}.erb"), File.join(deb_dir, deb_file), false, {:binding => binding})
        end

        # These could be templates, but their content is static, so that seems weird.
        File.open(File.join(deb_dir, "compat"), "w") {|f| f.puts("7") }
        FileUtils.mkdir_p(File.join(deb_dir, "source"))
        File.open(File.join(deb_dir, "source", "format"), "w") {|f| f.puts("3.0 (quilt)") }
      end

      # Method to derive the package name for the project
      #
      # @param project [Vanagon::Project] project to name
      # @return [String] name of the debian package for this project
      def package_name(project)
        "#{project.name}_#{project.version}-1_#{@architecture}.deb"
      end

      # Get the expected output dir for the debian packages. This allows us to
      # use some standard tools to ship internally.
      #
      # @return [String] relative path to where debian packages should be staged
      def output_dir
        File.join("deb", @codename)
      end

      # Constructor. Sets up some defaults for the debian platform and calls the parent constructor
      #
      # @param name [String] name of the platform
      # @return [Vanagon::Platform::DEB] the deb derived platform with the given name
      def initialize(name)
        @name = name
        @make = "/usr/bin/make"
        @patch = "/usr/bin/patch"
        @num_cores = "/usr/bin/nproc"
        super(name)
      end
    end
  end
end
