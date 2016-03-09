require 'vanagon/platform'
require 'vanagon/project'
require 'vanagon/common'


# These constants are defined for the purpose of the project/generic file merge tests
# to point these directories to test areas under the /tmp directory.
# This allows individual test cases to be specified accurately.
# The actual resources/windows/wix files under vanagon are avoided, as the necessary
# data structures are not available under the test conditions causing failures in the
# ERB template translation

WORK_BASE = "/tmp/vanwintest"
VANAGON_ROOT = "#{WORK_BASE}/generic"
PROJ_ROOT = "#{WORK_BASE}/project"
WORKDIR = "#{WORK_BASE}/workdir"
# Admittedly this might not be the best placed statement, but my limited rspec
# started to defeat me when it came to using "let" for wixtestfiles
WIXTESTFILES = File.expand_path("./spec/fixtures/wix/resources/windows/wix")

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
      :projname               => "test-proj",
      :block                  => %Q[ platform "windows-2012r2-x64" do |plat| plat.servicetype 'windows' end ]
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

      describe '#generate_msi_packaging_artifacts' do
        before(:each) do
          # Create Workdir and temp root directory
          FileUtils.mkdir_p("#{WORKDIR}/wix")
          FileUtils.mkdir_p("#{VANAGON_ROOT}/resources/windows/wix")
          FileUtils.mkdir_p("#{PROJ_ROOT}/resources/windows/wix")
          # Switch directory so that project specific folder points to tmp area
          @pwd = Dir.pwd
          Dir.chdir(PROJ_ROOT)
        end
        after(:each) do
          # Cleanup the complete work directory tree
          FileUtils.rm_rf("#{WORK_BASE}")
          Dir.chdir(@pwd)
        end

        it "Copies Wix File from product specific directory to output directory" do
          # setup source directories and run artifact generation
          FileUtils.cp("#{WIXTESTFILES}/file-1.wxs", "#{PROJ_ROOT}/resources/windows/wix/file-1.wxs")
          cur_plat._platform.generate_msi_packaging_artifacts(WORKDIR, plat[:projname], binding)
          # check the result
          expect(File).to exist("#{WORKDIR}/wix/file-1.wxs")
        end

        it "Copies Wix File from Vanagon directory to work directory" do
          # setup source directories and run artifact generation
          FileUtils.cp("#{WIXTESTFILES}/file-1.wxs", "#{VANAGON_ROOT}/resources/windows/wix/file-1.wxs")
          cur_plat._platform.generate_msi_packaging_artifacts(WORKDIR, plat[:projname], binding)
          # check the result
          expect(File).to exist("#{WORKDIR}/wix/file-1.wxs")
        end

        it "Picks Project Specific Wix File in favour of Generic Wix file" do
          # setup source directories and run artifact generation
          FileUtils.cp("#{WIXTESTFILES}/file-1.wxs", "#{PROJ_ROOT}/resources/windows/wix/file-wix.wxs")
          FileUtils.cp("#{WIXTESTFILES}/file-2.wxs", "#{VANAGON_ROOT}/resources/windows/wix/file-wix.wxs")
          cur_plat._platform.generate_msi_packaging_artifacts(WORKDIR, plat[:projname], binding)
          # check the result
          expect(FileUtils.compare_file("#{WIXTESTFILES}/file-1.wxs", "#{WORKDIR}/wix/file-wix.wxs")).to be_truthy
        end

        it "Picks Project Specific Wix File in favour of Generic ERB file" do
          # setup source directories and run artifact generation
          FileUtils.cp("#{WIXTESTFILES}/file-1.wxs", "#{PROJ_ROOT}/resources/windows/wix/file-wix.wxs")
          FileUtils.cp("#{WIXTESTFILES}/file-3.wxs.erb", "#{VANAGON_ROOT}/resources/windows/wix/file-wix.wxs.erb")
          cur_plat._platform.generate_msi_packaging_artifacts(WORKDIR, plat[:projname], binding)
          # check the result
          expect(FileUtils.compare_file("#{WIXTESTFILES}/file-1.wxs", "#{WORKDIR}/wix/file-wix.wxs")).to be_truthy
        end

        it "Picks Project Specific ERB File in favour of Generic Wix file" do
          # setup source directories and run artifact generation
          FileUtils.cp("#{WIXTESTFILES}/file-3.wxs.erb", "#{PROJ_ROOT}/resources/windows/wix/file-wix.wxs.erb")
          FileUtils.cp("#{WIXTESTFILES}/file-2.wxs", "#{VANAGON_ROOT}/resources/windows/wix/file-wix.wxs")
          cur_plat._platform.generate_msi_packaging_artifacts(WORKDIR, plat[:projname], binding)
          # check the result
          expect(FileUtils.compare_file("#{WIXTESTFILES}/file-3.wxs.erb", "#{WORKDIR}/wix/file-wix.wxs")).to be_truthy
        end

        it "Picks Project Specific ERB File in favour of Generic ERB file" do
          # setup source directories and run artifact generation
          FileUtils.cp("#{WIXTESTFILES}/file-3.wxs.erb", "#{PROJ_ROOT}/resources/windows/wix/file-wix.wxs.erb")
          FileUtils.cp("#{WIXTESTFILES}/file-4.wxs.erb", "#{VANAGON_ROOT}/resources/windows/wix/file-wix.wxs.erb")
          cur_plat._platform.generate_msi_packaging_artifacts(WORKDIR, plat[:projname], binding)
          # check the result
          expect(FileUtils.compare_file("#{WIXTESTFILES}/file-3.wxs.erb", "#{WORKDIR}/wix/file-wix.wxs")).to be_truthy
        end

        it "Copies Hierarchy of files from Product Specific Directory to output directory with ERB translation as necessary" do
          # setup source directories and run artifact generation
          FileUtils.cp_r("#{WIXTESTFILES}/", "#{PROJ_ROOT}/resources/windows/", :verbose => true)
          cur_plat._platform.generate_msi_packaging_artifacts(WORKDIR, plat[:projname], binding)
          # check the result
          expect(File).to exist("#{WORKDIR}/wix/file-1.wxs")
          expect(File).to exist("#{WORKDIR}/wix/file-2.wxs")
          expect(File).to exist("#{WORKDIR}/wix/file-3.wxs")
          expect(File).to exist("#{WORKDIR}/wix/file-4.wxs")
          expect(File).to exist("#{WORKDIR}/wix/project.filter.xslt")
          expect(File).to exist("#{WORKDIR}/wix/project.wxs")
          expect(File).to exist("#{WORKDIR}/wix/include/include-sample-1.wxs")
          expect(File).to exist("#{WORKDIR}/wix/ui/ui-sample-1.wxs")
          expect(File).to exist("#{WORKDIR}/wix/ui/bitmaps/bitmap.bmp")
          expect(File).not_to exist("#{WORKDIR}/wix/project.filter.xslt.erb")
          expect(File).not_to exist("#{WORKDIR}/wix/file-3.wxs.erb")
          expect(File).not_to exist("#{WORKDIR}/wix/file-4.wxs.erb")
        end

        it "Copies Hierarchy of files from vanagon directory to output directory with ERB translation as necessary" do
          # setup source directories and run artifact generation
          FileUtils.cp_r("#{WIXTESTFILES}/", "#{VANAGON_ROOT}/resources/windows/", :verbose => true)
          cur_plat._platform.generate_msi_packaging_artifacts(WORKDIR, plat[:projname], binding)
          # check the result
          expect(File).to exist("#{WORKDIR}/wix/file-1.wxs")
          expect(File).to exist("#{WORKDIR}/wix/file-2.wxs")
          expect(File).to exist("#{WORKDIR}/wix/file-3.wxs")
          expect(File).to exist("#{WORKDIR}/wix/file-4.wxs")
          expect(File).to exist("#{WORKDIR}/wix/project.filter.xslt")
          expect(File).to exist("#{WORKDIR}/wix/project.wxs")
          expect(File).to exist("#{WORKDIR}/wix/include/include-sample-1.wxs")
          expect(File).to exist("#{WORKDIR}/wix/ui/ui-sample-1.wxs")
          expect(File).to exist("#{WORKDIR}/wix/ui/bitmaps/bitmap.bmp")
          expect(File).not_to exist("#{WORKDIR}/wix/project.filter.xslt.erb")
          expect(File).not_to exist("#{WORKDIR}/wix/file-3.wxs.erb")
          expect(File).not_to exist("#{WORKDIR}/wix/file-4.wxs.erb")
        end


        describe "generate_wix_dirs" do

          it "returns one directory with install_service defaults" do
            cur_plat.instance_eval(plat[:block])
            comp = Vanagon::Component::DSL.new('service-test', {}, cur_plat._platform)
            comp.install_service('/opt/bin.exe')
            expect(cur_plat._platform.generate_wix_dirs([comp._component.service].flatten.compact)).to eq( \
<<-HERE
<Directory Name="opt" Id="opt">
<Directory Id="SERVICETESTBINDIR" />
</Directory>
HERE
            )
          end

          it "returns one directory with non-default name" do
            cur_plat.instance_eval(plat[:block])
            comp = Vanagon::Component::DSL.new('service-test', {}, cur_plat._platform)
            comp.install_service('/opt/bin.exe', nil, "service-test-2")
            expect(cur_plat._platform.generate_wix_dirs([comp._component.service].flatten.compact)).to eq( \
<<-HERE
<Directory Name="opt" Id="opt">
<Directory Id="SERVICETEST2BINDIR" />
</Directory>
HERE
            )
          end

          it "returns nested directory correctly with \\" do
            cur_plat.instance_eval(plat[:block])
            comp = Vanagon::Component::DSL.new('service-test', {}, cur_plat._platform)
            comp.install_service('root\\programfiles\\bin.exe')
            expect(cur_plat._platform.generate_wix_dirs([comp._component.service].flatten.compact)).to eq( \
<<-HERE
<Directory Name="root" Id="root">
<Directory Name="programfiles" Id="programfiles">
<Directory Id="SERVICETESTBINDIR" />
</Directory>
</Directory>
HERE
            )
          end

          it "removes any drive roots" do
            cur_plat.instance_eval(plat[:block])
            comp = Vanagon::Component::DSL.new('service-test', {}, cur_plat._platform)
            comp.install_service('C:\\programfiles\\bin.exe')
            expect(cur_plat._platform.generate_wix_dirs([comp._component.service].flatten.compact)).to eq( \
<<-HERE
<Directory Name="programfiles" Id="programfiles">
<Directory Id="SERVICETESTBINDIR" />
</Directory>
HERE
            )
          end

          it "removes SourceDir" do
            cur_plat.instance_eval(plat[:block])
            comp = Vanagon::Component::DSL.new('service-test', {}, cur_plat._platform)
            comp.install_service('SourceDir\\programfiles\\bin.exe')
            expect(cur_plat._platform.generate_wix_dirs([comp._component.service].flatten.compact)).to eq( \
<<-HERE
<Directory Name="programfiles" Id="programfiles">
<Directory Id="SERVICETESTBINDIR" />
</Directory>
HERE
            )
          end


          it "adds a second directory for the same input but different components" do
            cur_plat.instance_eval(plat[:block])
            comp = Vanagon::Component::DSL.new('service-test', {}, cur_plat._platform)
            comp.install_service('/programfiles/bin.exe')
            comp2 = Vanagon::Component::DSL.new('service-test-2', {}, cur_plat._platform)
            comp2.install_service('/programfiles/bin.exe')
            expect(cur_plat._platform.generate_wix_dirs([comp._component.service, comp2._component.service].flatten.compact)).to eq( \
<<-HERE
<Directory Name="programfiles" Id="programfiles">
<Directory Id="SERVICETESTBINDIR" />
<Directory Id="SERVICETEST2BINDIR" />
</Directory>
HERE
            )
          end

          it "returns correctly formatted multiple nested directories" do
            cur_plat.instance_eval(plat[:block])
            comp1 = Vanagon::Component::DSL.new('service-test1', {}, cur_plat._platform)
            comp1.install_service('/opt/oneUp/twoUp/bin.exe')
            comp2 = Vanagon::Component::DSL.new('service-test2', {}, cur_plat._platform)
            comp2.install_service('/opt/oneUpAgain/twoUp/bin.exe')
            comp3 = Vanagon::Component::DSL.new('service-test3', {}, cur_plat._platform)
            comp3.install_service('/opt/oneUpAgain/twoUpAgain/bin.exe')
            expect(cur_plat._platform.generate_wix_dirs([comp1._component.service, comp2._component.service, comp3._component.service].flatten.compact)).to eq( \
<<-HERE
<Directory Name="opt" Id="opt">
<Directory Name="oneUp" Id="oneUp">
<Directory Name="twoUp" Id="twoUp">
<Directory Id="SERVICETEST1BINDIR" />
</Directory>
</Directory>
<Directory Name="oneUpAgain" Id="oneUpAgain">
<Directory Name="twoUp" Id="twoUp">
<Directory Id="SERVICETEST2BINDIR" />
</Directory>
<Directory Name="twoUpAgain" Id="twoUpAgain">
<Directory Id="SERVICETEST3BINDIR" />
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
end
