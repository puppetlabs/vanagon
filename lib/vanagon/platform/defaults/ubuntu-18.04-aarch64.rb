platform "ubuntu-18.04-aarch64" do |plat|
  plat.servicedir "/lib/systemd/system"
  plat.defaultdir "/etc/default"
  plat.servicetype "systemd"
  plat.codename "bionic"

  packages = %w(
    autoconf
    build-essential
    cmake
    debhelper
    devscripts
    fakeroot
    libbz2-dev
    libreadline-dev
    libselinux1-dev
    openjdk-8-jre-headless
    pkg-config
    quilt
    rsync
    swig
    systemtap-sdt-dev
    zlib1g-dev
  )
  plat.provision_with "export DEBIAN_FRONTEND=noninteractive; apt-get update -qq; apt-get install -qy --no-install-recommends #{packages.join(' ')}"
  plat.install_build_dependencies_with "DEBIAN_FRONTEND=noninteractive; apt-get install -qy --no-install-recommends "
  plat.vmpooler_template "ubuntu-1804-arm64"
end
