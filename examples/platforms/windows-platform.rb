# For windows platforms this example assumes use of chocolatey and cygwin
platform "windows-2012r2-x86" do |plat|
  plat.servicetype "windows"

  # We use chocolatey by default to install build dependancies and provision things.
  # This can be overridden easily
  plat.provision_with "C:/ProgramData/chocolatey/bin/choco.exe install -y mingw-w64 -version 5.2.0 -debug"
  plat.provision_with "C:/ProgramData/chocolatey/bin/choco.exe install -y Wix310 -version 3.10.2 -debug -x86"

  plat.install_build_dependencies_with "C:/ProgramData/chocolatey/bin/choco.exe install -y"

  plat.make "/usr/bin/make"
  plat.patch "TMP=/var/tmp /usr/bin/patch.exe --binary"

  plat.platform_triple "i686-unknown-mingw32"

  plat.package_type "msi"
end
