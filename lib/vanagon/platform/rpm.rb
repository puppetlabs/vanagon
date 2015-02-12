require 'vanagon/utilities'
include Vanagon::Utilities

class Vanagon
  class Platform
    class RPM < Vanagon::Platform
      # The specific bits used to generate an rpm package for a given project
      #
      # @param project [Vanagon::Project] project to build an rpm package of
      # @return [Array] list of commands required to build an rpm package for the given project from a tarball
      def generate_package(project)
        ["mkdir -p $(tempdir)/rpmbuild/{SOURCES,SPECS,BUILD,RPMS,SRPMS}",
        "cp #{project.name}-#{project.version}.tar.gz $(tempdir)/rpmbuild/SOURCES",
        "cp file-list-for-rpm $(tempdir)/rpmbuild/SOURCES",
        "cp #{project.name}.spec $(tempdir)/rpmbuild/SPECS",
        "rpmbuild -bb #{rpm_defines} $(tempdir)/rpmbuild/SPECS/#{project.name}.spec",
        "mkdir -p output/#{output_dir}",
        "cp $(tempdir)/rpmbuild/*RPMS/**/*.rpm ./output/#{output_dir}"]
      end

      # Method to generate the files required to build an rpm package for the project
      #
      # @param workdir [String] working directory to stage the evaluated templates in
      # @param name [String] name of the project
      # @param binding [Binding] binding to use in evaluating the packaging templates
      def generate_packaging_artifacts(workdir, name, binding)
        erb_file(File.join(VANAGON_ROOT, "templates/rpm/project.spec.erb"), File.join(workdir, "#{name}.spec"), false, {:binding => binding})
      end

      # Method to derive the package name for the project
      #
      # @param project [Vanagon::Project] project to name
      # @return [String] name of the rpm package for this project
      def package_name(project)
        "#{project.name}-#{project.version}-1.#{@architecture}.rpm"
      end

      # Get the expected output dir for the rpm packages. This allows us to
      # use some standard tools to ship internally.
      #
      # @return [String] relative path to where rpm packages should be staged
      def output_dir
        File.join(@os_name, @os_version, "products", @architecture)
      end

      def rpm_defines
        defines =  %Q{--define '_topdir $(tempdir)/rpmbuild' }
        defines << %Q{--define "%dist .#{os_name}#{os_version}" }
        defines
      end

      # Constructor. Sets up some defaults for the rpm platform and calls the parent constructor
      #
      # @param name [String] name of the platform
      # @return [Vanagon::Platform::RPM] the rpm derived platform with the given name
      def initialize(name)
        @name = name
        @make = "/usr/bin/make"
        @patch = "/usr/bin/patch"
        @num_cores = "/bin/grep -c 'processor' /proc/cpuinfo"
        super(name)
      end
    end
  end
end
