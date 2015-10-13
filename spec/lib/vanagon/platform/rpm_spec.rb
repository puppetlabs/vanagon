require 'vanagon/platform'

describe "Vanagon::Platform::RPM" do
  platforms =[
      {
        :name                   => "el-5-i386",
        :os_name                => "el",
        :os_version             => "5",
        :architecture           => "i386",
        :output_dir             => "el/5/products/i386",
        :output_dir_with_target => "el/5/thing/i386",
        :block                  => %Q[ platform "el-5-i386" do |plat| end ]
      },
      {
        :name                   => "fedora-21-x86_64",
        :os_name                => "fedora",
        :os_version             => "21",
        :architecture           => "x86_64",
        :output_dir             => "fedora/21/products/x86_64",
        :output_dir_with_target => "fedora/21/thing/x86_64",
        :block                  => %Q[ platform "fedora-21-x86_64" do |plat| end ]
      },
      {
        :name                   => "cisco-wrlinux-7-x86_64",
        :os_name                => "fedora",
        :os_version             => "21",
        :architecture           => "x86_64",
        :output_dir             => "cisco-wrlinux/7/products/x86_64",
        :output_dir_with_target => "cisco-wrlinux/7/thing/x86_64",
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

      describe "#output_dir" do
        it "returns an output dir consistent with the packaging repo" do
          expect(cur_plat._platform.output_dir).to eq(plat[:output_dir])
        end

        it "adds the target repo in the right way" do
          expect(cur_plat._platform.output_dir('thing')).to eq(plat[:output_dir_with_target])
        end
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
