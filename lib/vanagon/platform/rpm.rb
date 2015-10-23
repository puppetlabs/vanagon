require 'vanagon/utilities'
include Vanagon::Utilities

class Vanagon
  class Platform
    class RPM < Vanagon::Platform
      # The specific bits used to generate an rpm package for a given project
      #
      # @param project [Vanagon::Project] project to build an rpm package of
      # @return [Array] list of commands required to build an rpm package for the given project from a tarball
      def generate_package(project)
        target_dir = project.repo ? output_dir(project.repo) : output_dir
        ["bash -c 'mkdir -p $(tempdir)/rpmbuild/{SOURCES,SPECS,BUILD,RPMS,SRPMS}'",
        "cp #{project.name}-#{project.version}.tar.gz $(tempdir)/rpmbuild/SOURCES",
        "cp file-list-for-rpm $(tempdir)/rpmbuild/SOURCES",
        "cp #{project.name}.spec $(tempdir)/rpmbuild/SPECS",
        "PATH=/opt/freeware/bin:$$PATH #{@rpmbuild} -bb --target #{@architecture} #{rpm_defines} $(tempdir)/rpmbuild/SPECS/#{project.name}.spec",
        "mkdir -p output/#{target_dir}",
        "cp $(tempdir)/rpmbuild/*RPMS/**/*.rpm ./output/#{target_dir}"]
      end

      # Method to generate the files required to build an rpm package for the project
      #
      # @param workdir [String] working directory to stage the evaluated templates in
      # @param name [String] name of the project
      # @param binding [Binding] binding to use in evaluating the packaging templates
      def generate_packaging_artifacts(workdir, name, binding)
        erb_file(File.join(VANAGON_ROOT, "templates/rpm/project.spec.erb"), File.join(workdir, "#{name}.spec"), false, { :binding => binding })
      end

      # Method to derive the package name for the project
      #
      # @param project [Vanagon::Project] project to name
      # @return [String] name of the rpm package for this project
      def package_name(project)
        "#{project.name}-#{project.version}-#{project.release}.#{project.noarch ? 'noarch' : @architecture}.rpm"
      end

      # Get the expected output dir for the rpm packages. This allows us to
      # use some standard tools to ship internally.
      #
      # @return [String] relative path to where rpm packages should be staged
      def output_dir(target_repo = "products")
        File.join(@os_name, @os_version, target_repo, @architecture)
      end

      def rpm_defines
        defines =  %(--define '_topdir $(tempdir)/rpmbuild' )
        # RPM doesn't allow dashes in the os_name. This was added to
        # convert cisco-wrlinux to cisco_wrlinux
        defines << %(--define 'dist .#{@os_name.gsub('-', '_')}#{@os_version}' )
      end

      def add_repository(definition)
        definition = URI.parse(definition)

        commands = ["rpm -q curl > /dev/null || yum -y install curl"]
        if definition.scheme =~ /^(http|ftp)/
          if File.extname(definition.path) == '.rpm'
            # repo definition is an rpm (like puppetlabs-release)
            commands << "curl -o local.rpm '#{definition}'; rpm -Uvh local.rpm; rm -f local.rpm"
          else
            reponame = "#{SecureRandom.hex}-#{File.basename(definition.path)}"
            reponame = "#{reponame}.repo" if File.extname(reponame) != '.repo'
            if is_cisco_wrlinux?
              commands << "curl -o '/etc/yum/repos.d/#{reponame}' '#{definition}'"
            else
              commands << "curl -o '/etc/yum.repos.d/#{reponame}' '#{definition}'"
            end
          end
        end

        commands
      end

      # Constructor. Sets up some defaults for the rpm platform and calls the parent constructor
      #
      # @param name [String] name of the platform
      # @return [Vanagon::Platform::RPM] the rpm derived platform with the given name
      def initialize(name)
        @name = name
        @make ||= "/usr/bin/make"
        @tar ||= "tar"
        @patch ||= "/usr/bin/patch"
        @num_cores ||= "/bin/grep -c 'processor' /proc/cpuinfo"
        @rpmbuild ||= "/usr/bin/rpmbuild"
        @bash = "/bin/bash"
        super(name)
      end
    end
  end
end
