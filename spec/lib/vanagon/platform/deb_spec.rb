require 'vanagon/platform/deb'

describe "Vanagon::Platform::DEB" do
  let(:platforms) do
    [
      {
        :name                   => "ubuntu-10.04-i386",
        :os_name                => "ubuntu",
        :os_version             => "10.04",
        :architecture           => "i386",
        :output_dir             => "deb/lucid/",
        :output_dir_with_target => "deb/lucid/thing",
        :codename               => "lucid",
      },
      {
        :name                   => "debian-7-amd64",
        :os_name                => "debian",
        :os_version             => "7",
        :architecture           => "amd64",
        :output_dir             => "deb/wheezy/",
        :output_dir_with_target => "deb/wheezy/thing",
        :codename               => "wheezy",
      },
    ]
  end

  describe "#output_dir" do
    it "returns an output dir consistent with the packaging repo" do
      platforms.each do |plat|

        plat_block = %Q[
        platform "#{plat[:name]}" do |plat|
          plat.codename "#{plat[:codename]}"
        end
        ]

        cur_plat = Vanagon::Platform::DSL.new(plat[:name])
        cur_plat.instance_eval(plat_block)
        expect(cur_plat._platform.output_dir).to eq(plat[:output_dir])
      end
    end

    it "adds the target repo in the right place" do
      platforms.each do |plat|

        plat_block = %Q[
        platform "#{plat[:name]}" do |plat|
          plat.codename "#{plat[:codename]}"
        end
        ]

        cur_plat = Vanagon::Platform::DSL.new(plat[:name])
        cur_plat.instance_eval(plat_block)
        expect(cur_plat._platform.output_dir('thing')).to eq(plat[:output_dir_with_target])
      end
    end
  end
end


