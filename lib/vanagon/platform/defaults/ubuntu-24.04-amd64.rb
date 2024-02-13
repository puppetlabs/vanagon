platform "ubuntu-24.04-amd64" do |plat|
  plat.servicedir "/lib/systemd/system"
  plat.defaultdir "/etc/default"
  plat.servicetype "systemd"
  plat.codename "noble"

  packages = %w(build-essential devscripts make quilt pkg-config debhelper rsync fakeroot cmake curl)
  plat.provision_with "export DEBIAN_FRONTEND=noninteractive; apt-get update -qq; apt-get install -qy --no-install-recommends #{packages.join(' ')}"
  plat.provision_with "curl https://apt.puppet.com/DEB-GPG-KEY-puppet-20250406 | apt-key add -"
  plat.install_build_dependencies_with "DEBIAN_FRONTEND=noninteractive; apt-get install -qy --no-install-recommends "
  plat.vmpooler_template "ubuntu-2404-x86_64"
end
