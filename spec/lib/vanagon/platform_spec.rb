require 'vanagon/platform'

describe "Vanagon::Platform" do
  let(:platforms) do
    [
      {
        :name                    => "debian-6-i386",
        :os_name                 => "debian",
        :os_version              => "6",
        :architecture            => "i386",
        :output_dir              => "debian/6/i386",
        :output_dir_with_target  => "debian/6/thing/i386",
        :output_dir_empty_string => "debian/6/i386",
        :block                   => %Q[ platform "debian-6-i386" do |plat| end ],
      },
      {
        :name                    => "el-5-i386",
        :os_name                 => "el",
        :os_version              => "5",
        :architecture            => "i386",
        :output_dir              => "el/5/products/i386",
        :output_dir_with_target  => "el/5/thing/i386",
        :output_dir_empty_string => "el/5/i386",
        :block                   => %Q[ platform "el-5-i386" do |plat| end ],
      },
      {
        :name                    => "debian-6-i386",
        :os_name                 => "debian",
        :os_version              => "6",
        :architecture            => "i386",
        :output_dir              => "updated/output",
        :output_dir_with_target  => "updated/output",
        :output_dir_empty_string => "updated/output",
        :block                   => %Q[ platform "debian-6-i386" do |plat| plat.output_dir "updated/output" end ],
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

  describe "#output_dir" do
    it "returns correct output dir" do
      platforms.each do |plat|
        cur_plat = Vanagon::Platform::DSL.new(plat[:name])
        cur_plat.instance_eval(plat[:block])
        expect(cur_plat._platform.output_dir).to eq(plat[:output_dir])
      end
    end

    it "adds the target repo in the right way" do
      platforms.each do |plat|
        cur_plat = Vanagon::Platform::DSL.new(plat[:name])
        cur_plat.instance_eval(plat[:block])
        expect(cur_plat._platform.output_dir('thing')).to eq(plat[:output_dir_with_target])
      end
    end

    it "does the right thing with empty strings" do
      platforms.each do |plat|
        cur_plat = Vanagon::Platform::DSL.new(plat[:name])
        cur_plat.instance_eval(plat[:block])
        expect(cur_plat._platform.output_dir('')).to eq(plat[:output_dir_empty_string])
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
