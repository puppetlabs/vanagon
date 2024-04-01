platform 'el-9-ppc64le' do |plat|
  plat.servicedir '/usr/lib/systemd/system'
  plat.defaultdir '/etc/sysconfig'
  plat.servicetype 'systemd'

  # Workaround for an issue with RedHat subscription metadata, see ITSYS-2543
  plat.provision_with('subscription-manager repos --disable rhel-9-for-ppc64le-baseos-rpms && subscription-manager repos --enable rhel-9-for-ppc64le-baseos-rpms --enable codeready-builder-for-rhel-9-ppc64le-rpms')

  packages = %w(
    autoconf
    automake
    cmake
    gcc-c++
    java-1.8.0-openjdk-devel
    libarchive
    libselinux-devel
    make
    patch
    perl-Getopt-Long
    readline-devel
    swig
    systemtap-sdt-devel
    zlib-devel
  )

  plat.provision_with("dnf install -y --allowerasing  #{packages.join(' ')}")
  plat.install_build_dependencies_with 'dnf install -y --allowerasing'
  plat.vmpooler_template 'redhat-9-power9'
end
