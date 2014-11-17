class Vanagon::Platform
  class DEB < Vanagon::Platform
    def generate_package(project)
      ["mkdir -p output/#{@name}",
      "mkdir -p $(tempdir)/#{project.name}-#{project.version}",
      "cp #{project.name}-#{project.version}.tar.gz $(tempdir)/#{project.name}_#{project.version}.orig.tar.gz",
      "cp -pr debian $(tempdir)/#{project.name}-#{project.version}",
      "gunzip -c #{project.name}-#{project.version}.tar.gz | tar -C '$(tempdir)/#{project.name}-#{project.version}' --strip-components 1 -xf -",
      "(cd $(tempdir)/#{project.name}-#{project.version}; debuild --no-lintian -uc -us)",
      "cp $(tempdir)/*.deb ./output/#{@name}"]
    end

    def generate_packaging_artifacts(workdir, name, binding)
      deb_dir = File.join(workdir, "debian")
      FileUtils.mkdir_p(deb_dir)

      # Lots of templates here
      ["control", "dirs", "rules", "install", "changelog"].each do |deb_file|
        erb_file(File.join(VANAGON_ROOT, "templates/#{deb_file}.erb"), File.join(deb_dir, deb_file), false, {:binding => binding})
      end

      # These could be templates, but their content is static, so that seems weird.
      File.open(File.join(deb_dir, "compat"), "w") {|f| f.puts("7") }
      FileUtils.mkdir_p(File.join(deb_dir, "source"))
      File.open(File.join(deb_dir, "source", "format"), "w") {|f| f.puts("3.0 (quilt)") }
    end

    def package_name(project)
      "#{project.name}_#{project.version}-1_#{@architecture}.deb"
    end
  end
end
