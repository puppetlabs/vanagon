platform "redhatfips-7-x86_64" do |plat|
  plat.servicedir "/usr/lib/systemd/system"
  plat.defaultdir "/etc/sysconfig"
  plat.servicetype "systemd"

  plat.add_build_repository "http://pl-build-tools.delivery.puppetlabs.net/yum/pl-build-tools-release-el-7.noarch.rpm"
  packages = %w(
    autoconf
    automake
    createrepo
    gcc
    make
    rpmdevtools
    rpm-libs
    rpm-sign
    rsync
    yum-utils
  )
  plat.provision_with "yum install --assumeyes #{packages.join(' ')}"
  plat.install_build_dependencies_with "yum install --assumeyes"
  plat.vmpooler_template "redhat-fips-7-x86_64"
end
