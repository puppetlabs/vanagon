require 'vanagon/platform/deb'

describe "Vanagon::Platform::DEB" do
  let(:platforms) do
    [
      {
        :name                   => "ubuntu-10.04-i386",
        :os_name                => "ubuntu",
        :os_version             => "10.04",
        :architecture           => "i386",
        :codename               => "lucid",
      },
      {
        :name                   => "debian-7-amd64",
        :os_name                => "debian",
        :os_version             => "7",
        :architecture           => "amd64",
        :codename               => "wheezy",
      },
    ]
  end
end


