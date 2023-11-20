platform "osx-14-x86_64" do |plat|
  plat.servicetype "launchd"
  plat.servicedir "/Library/LaunchDaemons"
  plat.codename "sonoma"

  plat.provision_with "export HOMEBREW_NO_EMOJI=true"
  plat.provision_with "export HOMEBREW_VERBOSE=true"
  plat.provision_with "export HOMEBREW_NO_ANALYTICS=1"

  plat.provision_with "sudo dscl . -create /Users/test"
  plat.provision_with "sudo dscl . -create /Users/test UserShell /bin/bash"
  plat.provision_with "sudo dscl . -create /Users/test UniqueID 1001"
  plat.provision_with "sudo dscl . -create /Users/test PrimaryGroupID 1000"
  plat.provision_with "sudo dscl . -create /Users/test NFSHomeDirectory /Users/test"
  plat.provision_with "sudo dscl . -passwd /Users/test password"
  plat.provision_with "sudo dscl . -merge /Groups/admin GroupMembership test"
  plat.provision_with "echo 'test ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/username"
  plat.provision_with "mkdir -p /etc/homebrew"
  plat.provision_with "cd /etc/homebrew"
  plat.provision_with "createhomedir -c -u test"
  plat.provision_with %Q(su test -c 'echo | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"')
  plat.vmpooler_template "macos-14-x86_64"
end
