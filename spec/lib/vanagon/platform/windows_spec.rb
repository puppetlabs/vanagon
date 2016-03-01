require 'vanagon/platform'
require 'vanagon/project'

# These constants are defined for the purpose of the project/generic file merge tests
# to point these directories to test areas under the /tmp directory.
# This allows individual test cases to be specified accurately.
# The actual resources/windows/wix files under vanagon are avoided, as the necessary
# data structures are not available under the test conditions causing failures in the
# ERB template translation

WORK_BASE = "/tmp/vanwintest"
VANAGON_ROOT = "#{WORK_BASE}/generic"
PROJ_ROOT = "#{WORK_BASE}/project"

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
      :block                  => %Q[ platform "windows-2012r2-x64" do |plat| end ]
    },
  ]

  platforms.each do |plat|
    context "on #{plat[:name]} we should behave ourselves" do
      let(:platform) { plat }
      let(:cur_plat) { Vanagon::Platform::DSL.new(plat[:name]) }
      let(:project) {  Vanagon::Project.new("test-project", platform) }
      let (:workdir) { "#{WORK_BASE}/workdir" }
      let (:wixtestfiles) { "/tmp/spec/fixtures/wix/resources/windows/wix" }

      before do
        cur_plat.instance_eval(plat[:block])
        FileUtils.mkdir_p("/tmp/spec/fixtures/wix/resources/windows")
        FileUtils.cp_r("spec/fixtures/wix/resources/windows/wix", "#{wixtestfiles}")
      end
      after do
        FileUtils.rm_rf("#{WORK_BASE}")
        FileUtils.rm_rf("/tmp/spec")
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
          FileUtils.mkdir_p("#{workdir}/wix")
          FileUtils.mkdir_p("#{VANAGON_ROOT}/resources/windows/wix")
          FileUtils.mkdir_p("#{PROJ_ROOT}/resources/windows/wix")
          @pwd = Dir.pwd
          Dir.chdir(PROJ_ROOT)
        end
        after(:each) do
          # Cleanup the complete work directory tree
          FileUtils.rm_rf("#{PROJ_ROOT}")
          FileUtils.rm_rf("#{VANAGON_ROOT}")
          FileUtils.rm_rf("#{workdir}/wix")
          Dir.chdir(@pwd)
        end

        it "Copies Wix File from product specific directory to output directory" do
          # setup source directories and run artifact generation
          FileUtils.cp("#{wixtestfiles}/file-1.wxs", "#{PROJ_ROOT}/resources/windows/wix/file-1.wxs")
          cur_plat._platform.generate_msi_packaging_artifacts(workdir, project, binding)
          # check the result
          expect(File).to exist("#{workdir}/wix/file-1.wxs")
        end

        it "Copies Wix File from Vanagon directory to work directory" do
          # setup source directories and run artifact generation
          FileUtils.cp("#{wixtestfiles}/file-1.wxs", "#{VANAGON_ROOT}/resources/windows/wix/file-1.wxs")
          cur_plat._platform.generate_msi_packaging_artifacts(workdir, project, binding)
          # check the result
          expect(File).to exist("#{workdir}/wix/file-1.wxs")
        end

        it "Picks Project Specific Wix File in favour of Generic Wix file" do
          # setup source directories and run artifact generation
          FileUtils.cp("#{wixtestfiles}/file-1.wxs", "#{PROJ_ROOT}/resources/windows/wix/file-wix.wxs")
          FileUtils.cp("#{wixtestfiles}/file-2.wxs", "#{VANAGON_ROOT}/resources/windows/wix/file-wix.wxs")
          cur_plat._platform.generate_msi_packaging_artifacts(workdir, project, binding)
          # check the result
          expect(FileUtils.compare_file("#{wixtestfiles}/file-1.wxs", "#{workdir}/wix/file-wix.wxs")).to be_truthy
        end

        it "Picks Project Specific Wix File in favour of Generic ERB file" do
          # setup source directories and run artifact generation
          FileUtils.cp("#{wixtestfiles}/file-1.wxs", "#{PROJ_ROOT}/resources/windows/wix/file-wix.wxs")
          FileUtils.cp("#{wixtestfiles}/file-3.wxs.erb", "#{VANAGON_ROOT}/resources/windows/wix/file-wix.wxs.erb")
          cur_plat._platform.generate_msi_packaging_artifacts(workdir, project, binding)
          # check the result
          expect(FileUtils.compare_file("#{wixtestfiles}/file-1.wxs", "#{workdir}/wix/file-wix.wxs")).to be_truthy
        end

        it "Picks Project Specific ERB File in favour of Generic Wix file" do
          # setup source directories and run artifact generation
          FileUtils.cp("#{wixtestfiles}/file-3.wxs.erb", "#{PROJ_ROOT}/resources/windows/wix/file-wix.wxs.erb")
          FileUtils.cp("#{wixtestfiles}/file-2.wxs", "#{VANAGON_ROOT}/resources/windows/wix/file-wix.wxs")
          cur_plat._platform.generate_msi_packaging_artifacts(workdir, project, binding)
          # check the result
          expect(FileUtils.compare_file("#{wixtestfiles}/file-3.wxs.erb", "#{workdir}/wix/file-wix.wxs")).to be_truthy
        end

        it "Picks Project Specific ERB File in favour of Generic ERB file" do
          # setup source directories and run artifact generation
          FileUtils.cp("#{wixtestfiles}/file-3.wxs.erb", "#{PROJ_ROOT}/resources/windows/wix/file-wix.wxs.erb")
          FileUtils.cp("#{wixtestfiles}/file-4.wxs.erb", "#{VANAGON_ROOT}/resources/windows/wix/file-wix.wxs.erb")
          cur_plat._platform.generate_msi_packaging_artifacts(workdir, project, binding)
          # check the result
          expect(FileUtils.compare_file("#{wixtestfiles}/file-3.wxs.erb", "#{workdir}/wix/file-wix.wxs")).to be_truthy
        end

        it "Copies Hierarchy of files from Product Specific Directory to output directory with ERB translation as necessary" do
          # setup source directories and run artifact generation
          FileUtils.cp_r("#{wixtestfiles}/", "#{PROJ_ROOT}/resources/windows/", :verbose => true)
          cur_plat._platform.generate_msi_packaging_artifacts(workdir, project, binding)
          # check the result
          expect(File).to exist("#{workdir}/wix/file-1.wxs")
          expect(File).to exist("#{workdir}/wix/file-2.wxs")
          expect(File).to exist("#{workdir}/wix/file-3.wxs")
          expect(File).to exist("#{workdir}/wix/file-4.wxs")
          expect(File).to exist("#{workdir}/wix/project.filter.xslt")
          expect(File).to exist("#{workdir}/wix/project.wxs")
          expect(File).to exist("#{workdir}/wix/include/include-sample-1.wxs")
          expect(File).to exist("#{workdir}/wix/ui/ui-sample-1.wxs")
          expect(File).to exist("#{workdir}/wix/ui/bitmaps/bitmap.bmp")
          expect(File).not_to exist("#{workdir}/wix/project.filter.xslt.erb")
          expect(File).not_to exist("#{workdir}/wix/file-3.wxs.erb")
          expect(File).not_to exist("#{workdir}/wix/file-4.wxs.erb")
        end

        it "Copies Hierarchy of files from vanagon directory to output directory with ERB translation as necessary" do
          # setup source directories and run artifact generation
          FileUtils.cp_r("#{wixtestfiles}/", "#{VANAGON_ROOT}/resources/windows/", :verbose => true)
          cur_plat._platform.generate_msi_packaging_artifacts(workdir, project, binding)
          # check the result
          expect(File).to exist("#{workdir}/wix/file-1.wxs")
          expect(File).to exist("#{workdir}/wix/file-2.wxs")
          expect(File).to exist("#{workdir}/wix/file-3.wxs")
          expect(File).to exist("#{workdir}/wix/file-4.wxs")
          expect(File).to exist("#{workdir}/wix/project.filter.xslt")
          expect(File).to exist("#{workdir}/wix/project.wxs")
          expect(File).to exist("#{workdir}/wix/include/include-sample-1.wxs")
          expect(File).to exist("#{workdir}/wix/ui/ui-sample-1.wxs")
          expect(File).to exist("#{workdir}/wix/ui/bitmaps/bitmap.bmp")
          expect(File).not_to exist("#{workdir}/wix/project.filter.xslt.erb")
          expect(File).not_to exist("#{workdir}/wix/file-3.wxs.erb")
          expect(File).not_to exist("#{workdir}/wix/file-4.wxs.erb")
        end
      end
    end
  end
end
