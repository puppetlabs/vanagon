platform "el-7-x86_64" do |plat|
  plat.servicedir "/usr/lib/systemd/system"
  plat.defaultdir "/etc/sysconfig"
  plat.servicetype "systemd"

  plat.add_build_repository "http://pl-build-tools.delivery.puppetlabs.net/yum/pl-build-tools-release-#{plat.get_os_name}-#{plat.get_os_version}.noarch.rpm"
  packages = %w(autoconf automake createrepo rsync gcc make rpmdevtools rpm-libs yum-utils rpm-sign)
  plat.provision_with "yum install --assumeyes #{packages.join(' ')}"
  plat.install_build_dependencies_with "yum install --assumeyes"
  plat.vmpooler_template "redhat-7-x86_64"
end
