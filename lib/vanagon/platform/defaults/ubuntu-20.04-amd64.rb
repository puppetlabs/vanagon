platform "ubuntu-20.04-amd64" do |plat|
  plat.servicedir "/lib/systemd/system"
  plat.defaultdir "/etc/default"
  plat.servicetype "systemd"
  plat.codename "focal"

  # Temporary fix to add focal-updates.list repo file because it is missing from the vmpooler image
  plat.provision_with "echo 'deb https://artifactory.delivery.puppetlabs.net/artifactory/ubuntu__remote focal-updates main restricted universe multiverse' > /etc/apt/sources.list.d/focal-updates.list;
  echo 'deb-src https://artifactory.delivery.puppetlabs.net/artifactory/ubuntu__remote focal-updates main restricted universe multiverse' >> /etc/apt/sources.list.d/focal-updates.list"
  
  packages = %w(build-essential devscripts make quilt pkg-config debhelper rsync fakeroot cmake)

  plat.provision_with "export DEBIAN_FRONTEND=noninteractive; apt-get update -qq; apt-get install -qy --no-install-recommends #{packages.join(' ')}"
  plat.provision_with "curl https://apt.puppet.com/DEB-GPG-KEY-puppet-20250406 | apt-key add -"
  plat.install_build_dependencies_with "DEBIAN_FRONTEND=noninteractive; apt-get install -qy --no-install-recommends "
  plat.vmpooler_template "ubuntu-2004-x86_64"
end
