class Vanagon
  class Platform
    class DEB < Vanagon::Platform
      # The specific bits used to generate a debian package for a given project
      #
      # @param project [Vanagon::Project] project to build a debian package of
      # @return [Array] list of commands required to build a debian package for the given project from a tarball
      def generate_package(project) # rubocop:disable Metrics/AbcSize
        target_dir = project.repo ? output_dir(project.repo) : output_dir
        copy_extensions = if project.source_artifacts
                            '*.{deb,buildinfo,tar.gz,changes,dsc}'
                          else
                            '*.deb'
                          end
        pkg_arch_opt = project.noarch ? "" : "-a#{@architecture}"
        pkg_arch_opt = '-aarm64' if pkg_arch_opt == '-aaarch64'

        ["mkdir -p output/#{target_dir}",
        "mkdir -p $(tempdir)/#{project.name}-#{project.version}",
        "cp #{project.name}-#{project.version}.tar.gz $(tempdir)/#{project.name}_#{project.version}.orig.tar.gz",
        "cat file-list >> debian/install",
        "cp -pr debian $(tempdir)/#{project.name}-#{project.version}",
        "gunzip -c #{project.name}-#{project.version}.tar.gz | '#{@tar}' -C '$(tempdir)/#{project.name}-#{project.version}' --strip-components 1 -xf -",
        "#{sed} -i 's/ /?/g' $(tempdir)/#{project.name}-#{project.version}/debian/install",
        "(cd $(tempdir)/#{project.name}-#{project.version}; debuild --no-lintian #{pkg_arch_opt} -uc -us)",
        "cp $(tempdir)/#{copy_extensions} ./output/#{target_dir}"]
      end

      # Method to generate the files required to build a debian package for the project
      #
      # @param workdir [String] working directory to stage the evaluated templates in
      # @param name [String] name of the project
      # @param binding [Binding] binding to use in evaluating the packaging templates
      # @param project [Vanagon::Project] Vanagon::Project we are building for
      def generate_packaging_artifacts(workdir, name, binding, project) # rubocop:disable Metrics/AbcSize
        deb_dir = File.join(workdir, "debian")
        FileUtils.mkdir_p(deb_dir)

        unless project.get_interest_triggers("install").empty? && project.get_interest_triggers("upgrade").empty? && project.get_activate_triggers.empty?
          erb_file(File.join(VANAGON_ROOT, "resources/deb/triggers.erb"), File.join(deb_dir, "#{name}.triggers"), false, { :binding => binding })
        end

        # Lots of templates here
        ["changelog", "conffiles", "control", "docs", "dirs", "install", "preinst", "postinst", "postrm", "prerm", "rules"].each do |deb_file|
          erb_file(File.join(VANAGON_ROOT, "resources/deb/#{deb_file}.erb"), File.join(deb_dir, deb_file), false, { :binding => binding })
        end

        # These could be templates, but their content is static, so that seems weird.
        File.open(File.join(deb_dir, 'compat'), 'w') { |f| f.puts('10') }
        FileUtils.mkdir_p(File.join(deb_dir, "source"))
        File.open(File.join(deb_dir, "source", "format"), "w") { |f| f.puts("3.0 (quilt)") }
      end

      # Method to derive the package name for the project
      #
      # @param project [Vanagon::Project] project to name
      # @return [String] name of the debian package for this project
      def package_name(project)
        "#{project.name}_#{project.version}-#{project.release}#{@codename}_#{project.noarch ? 'all' : @architecture}.deb"
      end

      # Get the expected output dir for the debian packages. This allows us to
      # use some standard tools to ship internally.
      #
      # @return [String] relative path to where debian packages should be staged
      def output_dir(target_repo = "")
        @output_dir ||= File.join("deb", @codename, target_repo)
      end

      # Returns the string to add a target repo to the platforms' provisioning
      #
      # @param definition [URI] A URI to a deb or list file
      # @return [String] The command to add the repo target to the system
      def add_repo_target(definition)
        if File.extname(definition.path) == '.deb'
          # repo definition is an deb (like puppetlabs-release)
          "#{@curl} -o local.deb '#{definition}' && dpkg -i local.deb; rm -f local.deb"
        else
          reponame = "#{SecureRandom.hex}-#{File.basename(definition.path)}"
          reponame = "#{reponame}.list" if File.extname(reponame) != '.list'
          "#{@curl} -o '/etc/apt/sources.list.d/#{reponame}' '#{definition}'"
        end
      end

      # Returns the string to add a gpg key to the platforms' provisioning
      #
      # @param gpg_key [URI] A URI to the gpg key
      # @return [String] The command to add the gpg key to the system
      def add_gpg_key(gpg_key)
        gpgname = "#{SecureRandom.hex}-#{File.basename(gpg_key.path)}"
        gpgname = "#{gpgname}.gpg" if gpgname !~ /\.gpg$/
        "#{@curl} -o '/etc/apt/trusted.gpg.d/#{gpgname}' '#{gpg_key}'"
      end

      # Returns the commands to add a given repo target and optionally a gpg key to the build system
      #
      # @param definition [String] URI to the repo (.deb or .list)
      # @param gpg_key [String, nil] URI to a gpg key for the repo
      def add_repository(definition, gpg_key = nil)
        # i.e., definition = http://builds.delivery.puppetlabs.net/puppet-agent/0.2.1/repo_configs/deb/pl-puppet-agent-0.2.1-wheezy.list
        # parse the definition and gpg_key if set to ensure they are both valid URIs
        definition = URI.parse(definition)
        gpg_key = URI.parse(gpg_key) if gpg_key
        provisioning = ["apt-get -qq update && DEBIAN_FRONTEND=noninteractive apt-get -qq install curl"]

        if definition.scheme =~ /^(http|ftp)/
          provisioning << add_repo_target(definition)
        end

        if gpg_key
          provisioning << add_gpg_key(gpg_key)
        end

        provisioning << "apt-get -qq update"
      end


      # Pass in a packaging override. This will get added to the rules file, and
      # is a good way to pass in arbitrary environment variables
      #
      # @param project
      # @param var the string that should be added to the build script.
      def package_override(project, var)
        project.package_overrides << var
      end

      def version_munger(version_string, default: '=')
        operator, version = super.split
        if operator =~ /^[<>]$/
          operator = "#{operator}#{operator}"
        end

        "#{operator} #{version}"
      end
      # Constructor. Sets up some defaults for the debian platform and calls the parent constructor
      #
      # @param name [String] name of the platform
      # @return [Vanagon::Platform::DEB] the deb derived platform with the given name
      def initialize(name)
        @name = name
        @make = "/usr/bin/make"
        @tar = "tar"
        @patch = "/usr/bin/patch"
        @num_cores = "/usr/bin/nproc"
        @curl = "curl --silent --show-error --fail --location"
        @valid_operators = ['<', '>', '<=', '>=', '=', '<<', '>>']
        super
      end
    end
  end
end
