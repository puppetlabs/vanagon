platform "sles-15-x86_64" do |plat|
  plat.servicedir "/usr/lib/systemd/system"
  plat.defaultdir "/etc/sysconfig"
  plat.servicetype "systemd"

  packages = %w(aaa_base autoconf automake rsync gcc gcc-c++ make rpm-build gettext-tools cmake)
  plat.provision_with "zypper -n --no-gpg-checks install -y #{packages.join(' ')}"
  plat.install_build_dependencies_with "zypper -n --no-gpg-checks install -y"
  plat.vmpooler_template "sles-15-x86_64"
end
