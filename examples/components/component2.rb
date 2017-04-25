component "component2" do |pkg, settings, platform|
  pkg.ref "1.2.3"
  pkg.url "git://git.example.com/my-app/component2.git"
  pkg.mirror "https://git.example.com/my-app/component2.git"
  pkg.mirror "git@git.example.com:my-app/component2.git"

  pkg.build_requires "component1"

  pkg.install do
    ["#{settings[:bindir]}/component1 install --configdir=#{settings[:sysconfdir]} --mandir=#{settings[:mandir]}"]
  end
end
