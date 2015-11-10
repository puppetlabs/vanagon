class Vanagon
  class Platform
    class Windows < Vanagon::Platform
      # The specific bits used to generate a windows package for a given project
      #
      # @param project [Vanagon::Project] project to build a windows package of
      # @return [Array] list of commands required to build a windows package for the given project from a tarball
      def generate_package(project)
        target_dir = project.repo ? output_dir(project.repo) : output_dir
        ["mkdir -p output/#{target_dir}",
        "touch output/#{target_dir}/#{project.name}-#{project.version}-#{project.release}-#{@architecture}.msi"]
      end

      # Method to generate the files required to build a windows package for the project
      #
      # @param workdir [String] working directory to stage the evaluated templates in
      # @param name [String] name of the project
      # @param binding [Binding] binding to use in evaluating the packaging templates
      def generate_packaging_artifacts(workdir, name, binding)
        win_dir = File.join(workdir, "windows")
        FileUtils.mkdir_p(win_dir)

        # We'll uncomment this once we have templates to parse here
        [""].each do |win_file|
          #erb_file(File.join(VANAGON_ROOT, "templates/win/#{win_file}.erb"), File.join(win_dir, win_file), false, { :binding => binding })
        end
      end

      # Method to derive the package name for the project
      #
      # @param project [Vanagon::Project] project to name
      # @return [String] name of the windows package for this project
      def package_name(project)
        "#{project.name}-#{project.version}-#{project.release}-#{@architecture}.msi"
      end

      # Get the expected output dir for the windows packages. This allows us to
      # use some standard tools to ship internally.
      #
      # @param target_repo [String] optional repo target for built packages defined
      #   at the project level
      # @return [String] relative path to where windows packages should be staged
      def output_dir(target_repo = "")
        File.join("windows", target_repo, @architecture)
      end

      # Constructor. Sets up some defaults for the windows platform and calls the parent constructor
      #
      # @param name [String] name of the platform
      # @return [Vanagon::Platform::DEB] the win derived platform with the given name
      def initialize(name)
        @target_user = "Administrator"
        super(name)
      end
    end
  end
end
