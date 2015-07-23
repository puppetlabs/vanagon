class Vanagon
  class Platform
    class RPM
      class Swix < Vanagon::Platform::RPM
        # The specific bits used to generate an SWIX package for a given project
        #
        # @param project [Vanagon::Project] project to build a SWIX package of
        # @return [Array] list of commands required to build the SWIX package
        # for the given project from an rpm
        def generate_package(project)
          target_dir = project.repo ? output_dir(project.repo) : output_dir

          commands = super(project)
          pkgname_swix = package_name(project)
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
        def package_name(project)
          "#{project.name}-#{project.version}-#{project.release}.#{os_name}#{os_version}.#{project.noarch ? 'noarch' : @architecture}.swix"
        end
      end
    end
  end
end
