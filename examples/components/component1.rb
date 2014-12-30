component "component1" do |pkg, settings, platform|
  pkg.version "1.2.3"
  pkg.md5sum "abcd1234"
  pkg.url "http://my-file-store.my-app.net/component1-1.2.3.tar.gz"

  pkg.build_requires "tar"

  if platform.is_deb?
    pkg.build_requires "zlib1g-dev"
  elsif platform.is_rpm?
    pkg.build_requires "zlib-devel"
  end

  pkg.configure do
    ["./configure --prefix=#{settings[:prefix]} "]
  end

  pkg.build do
    ["#{platform[:make]}"]
  end

  pkg.install do
    ["#{platform[:make]} install"]
  end
end
