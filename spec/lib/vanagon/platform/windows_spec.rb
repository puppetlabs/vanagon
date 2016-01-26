require 'vanagon/platform'

describe "Vanagon::Platform::Windows" do
  platforms =[
    {
      :name                   => "windows-2012r2-x64",
      :os_name                => "windows",
      :os_version             => "2012r2",
      :architecture           => "x64",
      :output_dir             => "windows/x64",
      :output_dir_with_target => "windows/thing/x64",
      :target_user            => "Administrator",
      :block                  => %Q[ platform "windows-2012r2-x64" do |plat| end ]
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

      describe '#target_user' do
        it "sets the target_user to 'Administrator'" do
          expect(cur_plat._platform.target_user).to eq(plat[:target_user])
        end
      end
    end
  end
end
