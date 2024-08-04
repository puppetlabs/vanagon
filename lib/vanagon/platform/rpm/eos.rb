class Vanagon
  class Platform
    class RPM
      class EOS < Vanagon::Platform::RPM
        # The specific bits used to generate an EOS package for a given project
        #
        # @param project [Vanagon::Project] project to build an EOS package of
        # @return [Array] list of commands required to build the EOS package
        # for the given project from an rpm or a swix
        def generate_package(project)
          # If nothing is passed in as platform type, default to building a swix package
          if project.platform.package_type.nil? || project.platform.package_type.empty?
            return generate_swix_package(project)
          else
            case project.platform.package_type
            when "rpm"
              return super
            when "swix"
              return generate_swix_package(project)
            else
              fail "I don't know how to build package type '#{project.platform.package_type}' for EOS. Teach me?"
            end
          end
        end

        # Method to derive the package name for the project
        #
        # @param project [Vanagon::Project] project to name
        # @return [String] name of the EOS package for this project
        def package_name(project)
          # If nothing is passed in as platform type, default to building a swix package
          if project.platform.package_type.nil? || project.platform.package_type.empty?
            return swix_package_name(project)
          else
            case project.platform.package_type
            when "rpm"
              return super
            when "swix"
              return swix_package_name(project)
            else
              fail "I don't know how to name package type '#{project.platform.package_type}' for EOS. Teach me?"
            end
          end
        end

        # The specific bits used to generate an SWIX package for a given project
        #
        # @param project [Vanagon::Project] project to build a SWIX package of
        # @return [Array] list of commands required to build the SWIX package
        # for the given project from an rpm
        def generate_swix_package(project)
          target_dir = project.repo ? output_dir(project.repo) : output_dir
          commands = ["bash -c 'mkdir -p $(tempdir)/rpmbuild/{SOURCES,SPECS,BUILD,RPMS,SRPMS}'",
          "cp #{project.name}-#{project.version}.tar.gz $(tempdir)/rpmbuild/SOURCES",
          "cp file-list-for-rpm $(tempdir)/rpmbuild/SOURCES",
          "cp #{project.name}.spec $(tempdir)/rpmbuild/SPECS",
          "PATH=/opt/freeware/bin:$$PATH #{@rpmbuild} -bb --target #{@architecture} #{rpm_defines} $(tempdir)/rpmbuild/SPECS/#{project.name}.spec",
          "mkdir -p output/#{target_dir}",
          "cp $(tempdir)/rpmbuild/*RPMS/**/*.rpm ./output/#{target_dir}"]


          pkgname_swix = swix_package_name(project)
          pkgname_rpm = pkgname_swix.sub(/swix$/, 'rpm')
          commands += ["echo 'format: 1' > ./output/#{target_dir}/manifest.txt",
          "echo \"primaryRpm: #{pkgname_rpm}\" >> ./output/#{target_dir}/manifest.txt",
          "echo #{pkgname_rpm}-sha1: `sha1sum ./output/#{target_dir}/#{pkgname_rpm}`",
          "cd ./output/#{target_dir}/ && zip #{pkgname_swix} manifest.txt #{pkgname_rpm}",
          "rm ./output/#{target_dir}/manifest.txt ./output/#{target_dir}/#{pkgname_rpm}"]

          commands
        end

        # Method to derive the package name for the project
        #
        # @param project [Vanagon::Project] project to name
        # @return [String] name of the SWIX package for this project
        def swix_package_name(project)
          "#{project.name}-#{project.version}-#{project.release}.#{os_name}#{os_version}.#{project.noarch ? 'noarch' : @architecture}.swix"
        end
      end
    end
  end
end
