require 'vanagon/platform'

describe "Vanagon::Platform" do
  let(:platforms) do
    [
      {
        :name         => "debian-6-i386",
        :os_name      => "debian",
        :os_version   => "6",
        :architecture => "i386",
      },
      {
        :name         => "el-5-i386",
        :os_name      => "el",
        :os_version   => "5",
        :architecture => "i386",
      },
      {
        :name         => "CumulusLinux-2.2-amd64",
        :os_name      => "CumulusLinux",
        :os_version   => "2.2",
        :architecture => "amd64",
      },
    ]
  end

  describe "#os_name" do
    it "returns the os_name for the platform" do
      platforms.each do |plat|
        cur_plat = Vanagon::Platform.new(plat[:name])
        expect(cur_plat.os_name).to eq(plat[:os_name])
      end
    end
  end

  describe "#os_version" do
    it "returns the the os_version for the platform" do
      platforms.each do |plat|
        cur_plat = Vanagon::Platform.new(plat[:name])
        expect(cur_plat.os_version).to eq(plat[:os_version])
      end
    end
  end

  describe "#architecture" do
    it "returns the architecture for the platform" do
      platforms.each do |plat|
        cur_plat = Vanagon::Platform.new(plat[:name])
        expect(cur_plat.architecture).to eq(plat[:architecture])
      end
    end
  end
end
