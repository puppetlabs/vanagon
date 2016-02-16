require 'vanagon/platform'
require 'vanagon/project'
require 'vanagon/common'
require 'vanagon/windows'


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
    context "on #{plat[:name]}" do
      let(:platform) { plat }
      let(:cur_plat) { Vanagon::Platform::DSL.new(plat[:name]) }
      let (:project_block) {
"project 'test-fixture' do |proj|
end" }

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

      describe "generate_wix_dirs" do

        it "raises error with no direcotries" do
          proj = Vanagon::Project::DSL.new('test-fixture', cur_plat._platform)
          proj.instance_eval(project_block)
          expect { cur_plat._platform.generate_wix_dirs(proj._project) }.to raise_error(Vanagon::Error, "ERROR No directories specified!")
        end


        it "returns one directory" do
          proj = Vanagon::Project::DSL.new('test-fixture', cur_plat._platform)
          proj.instance_eval(project_block)
          proj.directory('/opt', mode: '0755')
          expect(cur_plat._platform.generate_wix_dirs(proj._project)).to eq( \
<<-HERE
<Directory Name="opt" Id="opt">
</Directory>
HERE
          )
        end

        it "returns one directory with an id" do
          proj = Vanagon::Project::DSL.new('test-fixture', cur_plat._platform)
          proj.instance_eval(project_block)
          proj.directory('/opt', mode: '0755', wix_id: "root")
          expect(cur_plat._platform.generate_wix_dirs(proj._project)).to eq( \
<<-HERE
<Directory Name="opt" Id="root">
</Directory>
HERE
          )
        end

        it "returns nested directory correctly with \\" do
          proj = Vanagon::Project::DSL.new('test-fixture', cur_plat._platform)
          proj.instance_eval(project_block)
          proj.directory('root\\programfiles', mode: '0755', wix_id: "root")
          expect(cur_plat._platform.generate_wix_dirs(proj._project)).to eq( \
<<-HERE
<Directory Name="root" Id="root">
<Directory Name="programfiles" Id="root">
</Directory>
</Directory>
HERE
          )
        end

        it "removes any drive roots" do
          proj = Vanagon::Project::DSL.new('test-fixture', cur_plat._platform)
          proj.instance_eval(project_block)
          proj.directory('C:\\programfiles', mode: '0755', wix_id: "root")
          expect(cur_plat._platform.generate_wix_dirs(proj._project)).to eq( \
<<-HERE
<Directory Name="programfiles" Id="root">
</Directory>
HERE
          )
        end

        it "returns correctly formatted nested directories with id in last dir" do
          proj = Vanagon::Project::DSL.new('test-fixture', cur_plat._platform)
          proj.instance_eval(project_block)
          proj.directory('/opt/oneUp', mode: '0755', wix_id: "OU")
          expect(cur_plat._platform.generate_wix_dirs(proj._project)).to eq( \
<<-HERE
<Directory Name="opt" Id="opt">
<Directory Name="oneUp" Id="OU">
</Directory>
</Directory>
HERE
          )
        end

        it "returns correctly formatted nested directories" do
          proj = Vanagon::Project::DSL.new('test-fixture', cur_plat._platform)
          proj.instance_eval(project_block)
          proj.directory('/opt/oneUp', mode: '0755')
          expect(cur_plat._platform.generate_wix_dirs(proj._project)).to eq( \
<<-HERE
<Directory Name="opt" Id="opt">
<Directory Name="oneUp" Id="oneUp">
</Directory>
</Directory>
HERE
          )
        end


        it "returns correctly formatted multiple nested directories" do
          proj = Vanagon::Project::DSL.new('test-fixture', cur_plat._platform)
          proj.instance_eval(project_block)
          proj.directory('/opt/oneUp/twoUp', mode: '0755')
          proj.directory('/opt/oneUpAgain/twoUp', mode: '0755')
          proj.directory('/opt/oneUpAgain/twoUpAgain', mode: '0755', wix_id: 'TUA')
          expect(cur_plat._platform.generate_wix_dirs(proj._project)).to eq( \
<<-HERE
<Directory Name="opt" Id="opt">
<Directory Name="oneUp" Id="oneUp">
<Directory Name="twoUp" Id="twoUp">
</Directory>
</Directory>
<Directory Name="oneUpAgain" Id="oneUpAgain">
<Directory Name="twoUp" Id="twoUp">
</Directory>
<Directory Name="twoUpAgain" Id="TUA">
</Directory>
</Directory>
</Directory>
HERE
          )
        end

      end
    end
  end
end
