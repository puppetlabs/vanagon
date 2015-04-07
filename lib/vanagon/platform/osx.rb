class Vanagon
  class Platform
    class OSX < Vanagon::Platform
      # The specific bits used to generate a osx package for a given project
      #
      # @param project [Vanagon::Project] project to build a osx package of
      # @return [Array] list of commands required to build a osx package for the given project from a tarball
      def generate_package(project)
        target_dir = project.repo ? output_dir(project.repo) : output_dir
        # TODO This needs to be filled in with scriptlets to make OSX package building go
        ["mkdir -p output/#{target_dir}"]
      end

      # Method to generate the files required to build a debian package for the project
      #
      # @param workdir [String] working directory to stage the evaluated templates in
      # @param name [String] name of the project
      # @param binding [Binding] binding to use in evaluating the packaging templates
      def generate_packaging_artifacts(workdir, name, binding)
        # TODO This needs to be filled in with whatever templates are required for OSX
      end

      # Method to derive the package name for the project
      #
      # @param project [Vanagon::Project] project to name
      # @return [String] name of the osx package for this project
      def package_name(project)
        # TODO This may need updating to match reality
        "#{project.name}-#{project.version}-1#{@codename}_#{@architecture}.dmg"
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
        @patch = "/usr/bin/patch"
        @num_cores = "/usr/sbin/sysctl -n hw.physicalcpu"
        super(name)
      end
    end
  end
end
