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
    java-1.8.0-openjdk-devel
    libsepol
    libsepol-devel
    libselinux-devel
    make
    openssl-devel
    pkgconfig
    readline-devel
    rpmdevtools
    rpm-build
    rpm-libs
    rpm-sign
    rsync
    swig
    yum-utils
    zlib-devel
  )
  plat.provision_with "yum install --assumeyes #{packages.join(' ')}"
  plat.install_build_dependencies_with "yum install --assumeyes"
  plat.vmpooler_template "redhat-fips-7-x86_64"
end
