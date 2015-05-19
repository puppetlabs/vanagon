class Vanagon
  class Platform
    class Solaris10 < Vanagon::Platform
      # The specific bits used to generate a solaris package for a given project
      #
      # @param project [Vanagon::Project] project to build a solaris package of
      # @return [Array] list of commands required to build a solaris package for the given project from a tarball
      def generate_package(project)
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
          "rm #{name_and_version}.tar.gz",
          "cp -r packaging $(tempdir)/",

          # Here we are tweaking file/dir ownership and perms in the following ways
          # - All directories default to 0755 and root:sys
          # - All files default to root:sys
          # - The bin directory and all bin files are owned by root:bin instead of root:sys
          # - All files under lib are owned by root:bin instead of root:sys
          # - All .so files are owned by root:bin instead of root:sys
          %Q[(cd $(tempdir)/#{name_and_version}; pkgproto . | sort | awk ' \
            $$1 ~ /^d$$/ {print "d",$$2,$$3,"0755 root sys";} \
            $$1 ~ /^s$$/ {print;} \
            $$1 ~ /^f$$/ {print "f",$$2,$$3,$$4,"root sys";} \
            $$1 !~ /^[dfs]$$/ {print;} ' | /opt/csw/bin/gsed \
               -e '/^[fd] [^ ]\\+ .*[/]s\\?bin/ {s/root sys$$/root bin/}' \
               -e '/^[fd] [^ ]\\+ .*[/]lib[/][^/ ]\\+ / {s/root sys$$/root bin/}' \
               -e '/^[fd] [^ ]\\+ .*[/][^ ]\\+[.]so / {s/root sys$$/root bin/}' >> ../packaging/proto) ],

          # Actually build the package
          "pkgmk -f $(tempdir)/packaging/proto -b $(tempdir)/#{name_and_version} -o -d $(tempdir)/pkg/",
          "pkgtrans -s $(tempdir)/pkg/ $(tempdir)/pkg/#{pkg_name.gsub(/\.gz$/, '')} #{project.name}",
          "gzip -c $(tempdir)/pkg/#{pkg_name.gsub(/\.gz$/, '')} > output/#{target_dir}/#{pkg_name}",
        ]
      end

      # Method to generate the files required to build a solaris package for the project
      #
      # @param workdir [String] working directory to stage the evaluated templates in
      # @param name [String] name of the project
      # @param binding [Binding] binding to use in evaluating the packaging templates
      def generate_packaging_artifacts(workdir, name, binding)
        ["pkginfo", "depend", "preinstall", "preremove", "postinstall", "proto"].each do |template|
          target_dir = File.join(workdir, 'packaging')
          FileUtils.mkdir_p(target_dir)
          erb_file(File.join(VANAGON_ROOT, "templates/solaris/10/#{template}.erb"), File.join(target_dir, template), false, {:binding => binding})
        end
      end

      # Generate the scripts required to add a group to the package generated.
      # This will also update the group if it has changed.
      #
      # @param user [Vanagon::Common::User] the user to reference for the group
      # @return [String] the commands required to add a group to the system
      def add_group(user)
        # NB: system users aren't supported on solaris 10
        return <<-HERE.undent
          if ! getent group '#{user.group}' > /dev/null 2>&1; then
            /usr/sbin/groupadd '#{user.group}'
          fi
        HERE
      end

      # Generate the scripts required to add a user to the package generated.
      # This will also update the user if it has changed.
      #
      # @param user [Vanagon::Common::User] the user to create
      # @return [String] the commands required to add a user to the system
      def add_user(user)
        # NB: system users aren't supported on solaris 10
        # Solaris 10 also doesn't support long flags
        cmd_args = ["'#{user.name}'"]
        cmd_args.unshift "-g '#{user.group}'" if user.group
        cmd_args.unshift "-d '#{user.homedir}'" if user.homedir
        if user.shell
          cmd_args.unshift "-s '#{user.shell}'"
        elsif user.is_system
          # Even though system users aren't a thing, we can still disable the shell
          cmd_args.unshift "-s '/usr/bin/false'"
        end

        user_args = cmd_args.join("\s")

        return <<-HERE.undent
          if getent passwd '#{user.name}' > /dev/null 2>&1; then
            /usr/sbin/usermod #{user_args}
          else
            /usr/sbin/useradd #{user_args}
          fi
        HERE
      end

      # Method to derive the package name for the project
      #
      # @param project [Vanagon::Project] project to name
      # @return [String] name of the solaris package for this project
      def package_name(project)
        "#{project.name}-#{project.version}-#{@os_name}-#{@os_version}.#{@architecture}.pkg.gz"
      end

      # Get the expected output dir for the solaris 10 packages. This allows us to
      # use some standard tools to ship internally.
      #
      # @return [String] relative path to where solaris 10 packages should be staged
      def output_dir(target_repo = "")
        File.join("solaris", target_repo)
      end

      # Constructor. Sets up some defaults for the solaris 10 platform and calls the parent constructor
      #
      # @param name [String] name of the platform
      # @return [Vanagon::Platform::Solaris] the solaris 10 derived platform with the given name
      def initialize(name)
        @name = name
        @make = "/opt/csw/bin/gmake"
        @tar = "/usr/sfw/bin/gtar"
        @patch = "/opt/csw/bin/gpatch"
        # solaris 10
        @num_cores = "/usr/bin/kstat cpu_info | /usr/xpg4/bin/grep -E '[[:space:]]+core_id[[:space:]]' | wc -l"
        super(name)
      end
    end
  end
end


