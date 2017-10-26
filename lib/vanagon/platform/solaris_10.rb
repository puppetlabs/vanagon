class Vanagon
  class Platform
    class Solaris10 < Vanagon::Platform
      # The specific bits used to generate a solaris package for a given project
      #
      # @param project [Vanagon::Project] project to build a solaris package of
      # @return [Array] list of commands required to build a solaris package for the given project from a tarball
      def generate_package(project) # rubocop:disable Metrics/AbcSize
        target_dir = project.repo ? output_dir(project.repo) : output_dir
        name_and_version = "#{project.name}-#{project.version}"
        pkg_name = package_name(project)

        # Generate list of dirs in the package and create an exlplicit search
        # string for AWK to use in order to explicitly define which directories
        # to put in to the prototype file. Note that the Regexp object was avoided
        # because the output from Regexp would create failures from AWK as the conversion
        # from a Regexp obj to a string is formatted in a sub-optimal way that would have
        # required more string manipulation anyway. the string should be formatted like so:
        #         && ($$3 ~ /directory\/regex.*/ || $$3 ~ /another\/directory\/regex.*/)
        # for as many iterations as there are directries in the package
        pkgdirs = project.get_root_directories.map { |dir| dir.sub(/^\//, "").gsub(/([\/\.])+/, '\\\\\1') + '.*' }
        explicit_search_string = pkgdirs.map do |dir_regex|
          " $$3 ~ /" + dir_regex + "/ "
        end.join("||")

        # Here we maintain backward compatibility with older vanagon versions
        # that did this by default.  This shim should get removed at some point
        # in favor of just letting the makefile deliver the bill-of-materials
        # to the correct directory. This shouldn't be required at all then.
        if project.bill_of_materials.nil?
          bom_install = [
            # Move bill-of-materials into a docdir
            "mkdir -p $(tempdir)/#{name_and_version}/usr/share/doc/#{project.name}",
            "mv $(tempdir)/#{name_and_version}/bill-of-materials $(tempdir)/#{name_and_version}/usr/share/doc/#{project.name}/bill-of-materials",
          ]
        else
          bom_install = []
        end

        [
          # Set up our needed directories
          "mkdir -p $(tempdir)/#{name_and_version}",
          "mkdir -p $(tempdir)/pkg",
          "mkdir -p output/#{target_dir}",

          # Unpack the project and stage the packaging artifacts
          "gunzip -c #{name_and_version}.tar.gz | '#{@tar}' -C '$(tempdir)' -xf -",

          bom_install,

          "cp -r packaging $(tempdir)/",

          # Here we are tweaking file/dir ownership and perms in the following ways
          # - All directories default to 0755 and root:sys
          # - All files default to root:sys
          # - The bin directory and all bin files are owned by root:bin instead of root:sys
          # - All files under lib are owned by root:bin instead of root:sys
          # - All .so files are owned by root:bin instead of root:sys
          # - Explicity only include directories in the package contents
          #   (this should exclude things like root/bin root/var and such)
          %((cd $(tempdir)/#{name_and_version}; pkgproto . | sort | awk ' \
            $$1 ~ /^d$$/ && (#{explicit_search_string}) {print "d",$$2,$$3,"0755 root sys";} \
            $$1 ~ /^s$$/ {print;} \
            $$1 ~ /^f$$/ {print "f",$$2,$$3,$$4,"root sys";} \
            $$1 !~ /^[dfs]$$/ {print;} ' | /opt/csw/bin/gsed \
               -e '/^[fd] [^ ]\\+ .*[/]s\\?bin[^ ]\\+/ {s/root sys$$/root bin/}' \
               -e '/^[fd] [^ ]\\+ .*[/]lib[/][^ ]\\+/ {s/root sys$$/root bin/}' \
               -e '/^[fd] [^ ]\\+ .*[/][^ ]\\+[.]so/ {s/root sys$$/root bin/}' >> ../packaging/proto)),
          %((cd $(tempdir); #{project.get_directories.map { |dir| "/opt/csw/bin/ggrep -q 'd none #{dir.path.sub(/^\//, '')}' packaging/proto || echo 'd none #{dir.path.sub(/^\//, '')} #{dir.mode || '0755'} #{dir.owner || 'root'} #{dir.group || 'sys'}' >> packaging/proto" }.join('; ')})),

          # Actually build the package
          "pkgmk -f $(tempdir)/packaging/proto -b $(tempdir)/#{name_and_version} -o -d $(tempdir)/pkg/",
          "pkgtrans -s $(tempdir)/pkg/ $(tempdir)/pkg/#{pkg_name.gsub(/\.gz$/, '')} #{project.name}",
          "gzip -c $(tempdir)/pkg/#{pkg_name.gsub(/\.gz$/, '')} > output/#{target_dir}/#{pkg_name}",
        ].flatten.compact
      end

      # Method to generate the files required to build a solaris package for the project
      #
      # @param workdir [String] working directory to stage the evaluated templates in
      # @param name [String] name of the project
      # @param binding [Binding] binding to use in evaluating the packaging templates
      # @param project [Vanagon::Project] Vanagon::Project we are building for
      def generate_packaging_artifacts(workdir, name, binding, project)
        ["pkginfo", "depend", "preinstall", "preremove", "postinstall", "proto"].each do |template|
          target_dir = File.join(workdir, 'packaging')
          FileUtils.mkdir_p(target_dir)
          erb_file(File.join(VANAGON_ROOT, "resources/solaris/10/#{template}.erb"), File.join(target_dir, template), false, { :binding => binding })
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
      def add_user(user) # rubocop:disable Metrics/AbcSize
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
        "#{project.name}-#{project.version}-#{project.release}.#{@architecture}.pkg.gz"
      end

      # Because solaris has multiple terrible ways to install packages, we have
      # this method which generates a shell script to be executed on the system
      # which will install all of the build dependencies
      #
      # @param build_dependencies [Array] list of all build dependencies to install
      # @return [String] a command to install all of the build dependencies
      def install_build_dependencies(build_dependencies) # rubocop:disable Metrics/AbcSize
        http = []
        pkgutil = []
        noasks = ["instance=overwrite", "partial=nocheck", "runlevel=nocheck", "idepend=nocheck", "rdepend=nocheck", "space=nocheck", "setuid=nocheck", "conflict=nocheck", "action=nocheck", "basedir=default"]
        noask_command = noasks.map { |noask| "echo '#{noask}' >> /var/tmp/noask" }.join('; ')

        build_dependencies.each do |build_dependency|
          if build_dependency =~ /^http.*\.gz/
            # Fetch, unpack, install...this assumes curl is present.
            package = build_dependency.sub(/^http.*\//, '')
            http << "tmpdir=$(mktemp -p /var/tmp -d); (cd ${tmpdir} && curl -O #{build_dependency} && gunzip -c #{package} | pkgadd -d /dev/stdin -a /var/tmp/noask all)"
          else
            # Opencsw dependencies. At this point we assume that pkgutil is installed.
            pkgutil << build_dependency
          end
        end

        command = ''
        unless pkgutil.empty?
          command << "/opt/csw/bin/pkgutil -y -i #{pkgutil.join("\s")}; "
        end

        unless http.empty?
          command << "echo -n > /var/tmp/noask; #{noask_command}; "
          command << http.join('; ')
        end

        command
      end

      # Constructor. Sets up some defaults for the solaris 10 platform and calls the parent constructor
      #
      # @param name [String] name of the platform
      # @return [Vanagon::Platform::Solaris] the solaris 10 derived platform with the given name
      def initialize(name)
        @name = name
        @make = "/opt/csw/bin/gmake"
        @tar = "/usr/sfw/bin/gtar"
        @patch = "/usr/bin/gpatch"
        @shasum = "/opt/csw/bin/shasum"
        # solaris 10
        @num_cores = "/usr/bin/kstat cpu_info | awk '{print $$1}' | grep '^core_id$$' | wc -l"
        super(name)
        if @architecture == "sparc"
          @platform_triple = "sparc-sun-solaris2.#{@os_version}"
        elsif @architecture == "i386"
          @platform_triple = "i386-pc-solaris2.#{@os_version}"
        end
      end
    end
  end
end


