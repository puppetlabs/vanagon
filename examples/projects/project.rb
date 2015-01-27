project "my-app" do |proj|
  # Project level settings our components will care about
  proj.setting(:prefix, "/opt/my-app")
  proj.setting(:sysconfdir, "/etc/my-app")
  proj.setting(:logdir, "/var/log/my-app")
  proj.setting(:bindir, File.join(proj.prefix, "bin"))
  proj.setting(:libdir, File.join(proj.prefix, "lib"))
  proj.setting(:includedir, File.join(proj.prefix, "include"))
  proj.setting(:datadir, File.join(proj.prefix, "share"))
  proj.setting(:mandir, File.join(proj.datadir, "man"))

  proj.description "This app does some things."
  proj.version "1.2.3"
  proj.license "ASL 2.0"
  proj.vendor "Me <info@my-app.com>"
  proj.homepage "https://www.my-app.com"
  proj.requires "glibc"

  proj.component "component1"
  proj.component "component2"

  # directory adds a directory (and its contents) to the package that is created
  proj.directory proj.prefix
  proj.directory proj.sysconfdir
  proj.directory proj.logdir
end
