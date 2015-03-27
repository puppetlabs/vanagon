require 'vanagon/platform/rpm'

describe "Vanagon::Platform::RPM" do
  let(:platforms) do
    [
      {
        :name                   => "el-5-i386",
        :os_name                => "el",
        :os_version             => "5",
        :architecture           => "i386",
        :output_dir             => "el/5/products/i386",
        :output_dir_with_target => "el/5/thing/i386",
      },
      {
        :name                   => "fedora-21-x86_64",
        :os_name                => "fedora",
        :os_version             => "21",
        :architecture           => "x86_64",
        :output_dir             => "fedora/21/products/x86_64",
        :output_dir_with_target => "fedora/21/thing/x86_64",
      },
    ]
  end

  describe "#output_dir" do
    it "returns an output dir consistent with the packaging repo" do
      platforms.each do |plat|
        cur_plat = Vanagon::Platform::RPM.new(plat[:name])
        expect(cur_plat.output_dir).to eq(plat[:output_dir])
      end
    end

    it "adds the target repo in the right way" do
      platforms.each do |plat|
        cur_plat = Vanagon::Platform::RPM.new(plat[:name])
        expect(cur_plat.output_dir('thing')).to eq(plat[:output_dir_with_target])
      end
    end
  end
end

