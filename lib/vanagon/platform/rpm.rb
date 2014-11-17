require 'vanagon/utilities'
include Vanagon::Utilities

class Vanagon::Platform
  class RPM
    def self.generate_package(project, platform)
      ["mkdir -p $(tempdir)/rpmbuild/{SOURCES,SPECS,BUILD,RPMS,SRPMS}",
      "cp #{project.name}-#{project.version}.tar.gz $(tempdir)/rpmbuild/SOURCES",
      "cp #{project.name}.spec $(tempdir)/rpmbuild/SPECS",
      "rpmbuild -bb --define '_topdir $(tempdir)/rpmbuild' $(tempdir)/rpmbuild/SPECS/#{project.name}.spec",
      "mkdir -p output/#{platform.name}",
      "cp $(tempdir)/rpmbuild/*RPMS/**/*.rpm ./output/#{platform.name}"]
    end

    def self.generate_packaging_artifacts(workdir, name, binding)
      erb_file(File.join(VANAGON_ROOT, "templates/project.spec.erb"), File.join(workdir, "#{name}.spec"), false, {:binding => binding})
    end

    def self.package_name(project, platform)
      "#{project.name}-#{project.version}-1.#{platform.architecture}.rpm"
    end
  end
end
