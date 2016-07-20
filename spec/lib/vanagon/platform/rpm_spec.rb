require 'vanagon/platform'

describe "Vanagon::Platform::RPM" do
  platforms =[
      {
        :name                   => "el-5-i386",
        :os_name                => "el",
        :os_version             => "5",
        :architecture           => "i386",
        :block                  => %Q[ platform "el-5-i386" do |plat| end ]
      },
      {
        :name                   => "fedora-21-x86_64",
        :os_name                => "fedora",
        :os_version             => "21",
        :architecture           => "x86_64",
        :block                  => %Q[ platform "fedora-21-x86_64" do |plat| end ]
      },
      {
        :name                   => "cisco-wrlinux-7-x86_64",
        :os_name                => "fedora",
        :os_version             => "21",
        :architecture           => "x86_64",
        :block                  => %Q[ platform "cisco-wrlinux-7-x86_64" do |plat| end ]
      },
    ]

  platforms.each do |plat|
    context "on #{plat[:name]} we should behave ourselves" do
      let(:platform) { plat }
      let(:cur_plat) { Vanagon::Platform::DSL.new(plat[:name]) }

      before do
        cur_plat.instance_eval(plat[:block])
      end

      describe '#rpm_defines' do
        it "removes dashes from the dist macro" do
          expected_dist = "--define 'dist .#{cur_plat._platform.os_name.gsub('-', '_')}#{cur_plat._platform.os_version}'"
          expect(cur_plat._platform.rpm_defines).to include(expected_dist)
        end
      end
    end
  end
end
