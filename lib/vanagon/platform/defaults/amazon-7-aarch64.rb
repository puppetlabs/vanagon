platform "amazon-7-aarch64" do |plat|
  plat.servicedir "/usr/lib/systemd/system"
  plat.defaultdir "/etc/sysconfig"
  plat.servicetype "systemd"

  packages = %w(autoconf automake createrepo gcc gcc-c++ rsync cmake3  make rpm-libs rpm-build libarchive)
  plat.provision_with("yum install -y --nogpgcheck  #{packages.join(' ')}")
  plat.install_build_dependencies_with "yum install --assumeyes"
  plat.vmpooler_template "amazon-7-arm64"
end
