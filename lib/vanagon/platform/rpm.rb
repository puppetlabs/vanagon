require 'vanagon/utilities'
include Vanagon::Utilities

class Vanagon
  class Platform
    class RPM < Vanagon::Platform
      def generate_package(project)
        ["mkdir -p $(tempdir)/rpmbuild/{SOURCES,SPECS,BUILD,RPMS,SRPMS}",
        "cp #{project.name}-#{project.version}.tar.gz $(tempdir)/rpmbuild/SOURCES",
        "cp #{project.name}.spec $(tempdir)/rpmbuild/SPECS",
        "rpmbuild -bb --define '_topdir $(tempdir)/rpmbuild' $(tempdir)/rpmbuild/SPECS/#{project.name}.spec",
        "mkdir -p output/#{output_dir}",
        "cp $(tempdir)/rpmbuild/*RPMS/**/*.rpm ./output/#{output_dir}"]
      end

      def generate_packaging_artifacts(workdir, name, binding)
        erb_file(File.join(VANAGON_ROOT, "templates/project.spec.erb"), File.join(workdir, "#{name}.spec"), false, {:binding => binding})
      end

      def package_name(project)
        "#{project.name}-#{project.version}-1.#{@architecture}.rpm"
      end

      def output_dir
        File.join(@os_name, @os_version, "products", @architecture)
      end

      def initialize(name)
        @name = name
        @make = "/usr/bin/make"
        @patch = "/usr/bin/patch"
        super(name)
      end
    end
  end
end
