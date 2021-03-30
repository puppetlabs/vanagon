platform "fedora-31-x86_64" do |plat|
  plat.servicedir "/usr/lib/systemd/system"
  plat.defaultdir "/etc/sysconfig"
  plat.servicetype "systemd"
  plat.dist "fc31"

  packages = %w(autoconf automake cmake createrepo rsync gcc gcc-c++ make rpmdevtools rpm-libs rpm-sign)
  plat.provision_with "/usr/bin/dnf install -y --best --allowerasing  #{packages.join(' ')}"
  plat.install_build_dependencies_with "/usr/bin/dnf install -y --best --allowerasing"
  plat.vmpooler_template "fedora-31-x86_64"
end
