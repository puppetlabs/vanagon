class Vanagon
  class Platform
    class Solaris11 < Vanagon::Platform
      # The specific bits used to generate a solaris package for a given project
      #
      # @param project [Vanagon::Project] project to build a solaris package of
      # @return [Array] list of commands required to build a solaris package for the given project from a tarball
      def generate_package(project) # rubocop:disable Metrics/AbcSize
        target_dir = project.repo ? output_dir(project.repo) : output_dir
        name_and_version = "#{project.name}-#{project.version}"
        pkg_name = package_name(project)

        [
          # Set up our needed directories
          "mkdir -p $(tempdir)/#{name_and_version}",
          "mkdir -p $(tempdir)/pkg",
          "mkdir -p output/#{target_dir}",

          # Unpack the project and stage the packaging artifacts
          "gunzip -c #{name_and_version}.tar.gz | '#{@tar}' -C '$(tempdir)' -xf -",
          "cp -r packaging $(tempdir)/",
          "pkgrepo create $(tempdir)/repo",
          "pkgrepo set -s $(tempdir)/repo publisher/prefix=#{project.identifier}",

          "(cd $(tempdir); pkgsend generate #{name_and_version} | pkgfmt >> packaging/#{project.name}.p5m.1)",

          # Actually build the package
          "(cd $(tempdir)/packaging; pkgmogrify -DARCH=`uname -p` #{project.name}.p5m.1 #{project.name}.p5m | pkgfmt > #{project.name}.p5m.2)",
          "pkglint $(tempdir)/packaging/#{project.name}.p5m.2",
          "pkgsend -s 'file://$(tempdir)/repo' publish -d '$(tempdir)/#{name_and_version}' --fmri-in-manifest '$(tempdir)/packaging/#{project.name}.p5m.2'",
          "pkgrecv -s 'file://$(tempdir)/repo' -a -d 'output/#{target_dir}/#{pkg_name}' '#{project.name}@#{ips_version(project.version, project.release)}'",

          # Now make sure the package we built isn't totally broken (but not when cross-compiling)
          %(if [ "#{@architecture}" = `uname -p` ]; then pkg install -nv -g 'output/#{target_dir}/#{pkg_name}' '#{project.name}@#{ips_version(project.version, project.release)}'; fi),
        ]
      end

      # Method to generate the files required to build a solaris package for the project
      #
      # @param workdir [String] working directory to stage the evaluated templates in
      # @param name [String] name of the project
      # @param binding [Binding] binding to use in evaluating the packaging templates
      # @param project [Vanagon::Project] Vanagon::Project we are building for
      def generate_packaging_artifacts(workdir, name, binding, project)
        target_dir = File.join(workdir, 'packaging')
        FileUtils.mkdir_p(target_dir)
        erb_file(File.join(VANAGON_ROOT, "resources/solaris/11/p5m.erb"), File.join(target_dir, "#{name}.p5m"), false, { :binding => binding })
      end

      # Generate the scripts required to add a group to the package generated.
      # This will also update the group if it has changed.
      #
      # @param user [Vanagon::Common::User] the user to reference for the group
      # @return [String] the commands required to add a group to the system
      def add_group(user)
        "group groupname=#{user.group}"
      end

      # Helper to setup an IPS build repo on a target system
      # http://docs.oracle.com/cd/E36784_01/html/E36802/gkkek.html
      #
      # @param uri [String] uri of the repository to add
      # @param origin [String] origin of the repository
      # @return [String] the command required to add an ips build repository
      def add_repository(uri, origin)
        "pkg set-publisher -G '*' -g #{uri} #{origin}"
      end

      # Generate the scripts required to add a user to the package generated.
      # This will also update the user if it has changed.
      #
      # @param user [Vanagon::Common::User] the user to create
      # @return [String] the commands required to add a user to the system
      def add_user(user)
        command = "user username=#{user.name}"
        command << " group=#{user.group}" if user.group
        command << " home-dir=#{user.homedir}" if user.homedir
        if user.shell
          command << " login-shell=#{user.shell}"
        elsif user.is_system
          command << " login-shell=/usr/bin/false"
        end

        command
      end

      # Method to derive the package name for the project
      #
      # @param project [Vanagon::Project] project to name
      # @return [String] name of the solaris package for this project
      def package_name(project)
        "#{project.name}@#{ips_version(project.version, project.release)}.#{@architecture}.p5p"
      end

      # Method to transform a standard version into the format expected by IPS
      # packages
      #
      # @param version [String] Standard package version
      # @param release [String] Standard package release
      # @return [String] version in IPS format
      def ips_version(version, release)
        version = version.gsub(/[a-zA-Z]/, '')
        version = version.gsub(/(^-)|(-$)/, '')

        # Here we strip leading 0 from version components but leave singular 0 on their own.
        version = version.split('.').map(&:to_i).join('.')
        "#{version},5.11-#{release}"
      end

      # Constructor. Sets up some defaults for the solaris 11 platform and calls the parent constructor
      #
      # @param name [String] name of the platform
      # @return [Vanagon::Platform::Solaris] the solaris 11 derived platform with the given name
      def initialize(name)
        @name = name
        @make = "/usr/bin/gmake"
        @tar = "/usr/bin/gtar"
        @patch = "/usr/bin/gpatch"
        @sed = "/usr/gnu/bin/sed"
        @num_cores = "/usr/bin/kstat cpu_info | /usr/bin/ggrep -E '[[:space:]]+core_id[[:space:]]' | wc -l"
        super
        if @architecture == "sparc"
          @platform_triple = "sparc-sun-solaris2.#{@os_version}"
        elsif @architecture == "i386"
          @platform_triple = "i386-pc-solaris2.#{@os_version}"
        end
      end
    end
  end
end
