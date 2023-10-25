platform "amazon-2023-x86_64" do |plat|
  plat.servicedir "/usr/lib/systemd/system"
  plat.defaultdir "/etc/sysconfig"
  plat.servicetype "systemd"

  packages = %w(gcc gcc-c++ autoconf automake createrepo rsync cmake make rpm-libs rpm-build rpm-sign libtool libarchive)
  plat.provision_with "dnf install -y --allowerasing #{packages.join(' ')}"
  plat.install_build_dependencies_with "dnf install -y --allowerasing "
  plat.vmpooler_template "amazon-2023-x86_64"
end
