require 'vanagon/project'
require 'vanagon/driver'

describe 'Vanagon::Project' do
  let(:component) { double(Vanagon::Component) }
  let(:cur_plat) { Vanagon::Platform::DSL.new('el-7-x86_64') }
  let(:configdir) { '/a/b/c' }

  let(:project_block) {
    "project 'test-fixture' do |proj|
    proj.component 'some-component'
    end"
  }

  before do
    allow_any_instance_of(Vanagon::Project::DSL).to receive(:puts)
    allow(Vanagon::Driver).to receive(:configdir).and_return(configdir)
    allow(Vanagon::Component).to receive(:load_component).with('some-component', any_args).and_return(component)
  end

  describe '#get_root_directories' do
    let(:test_sets) do
      [
        {
          :directories => ["/opt/puppetlabs/bin", "/etc/puppetlabs", "/var/log/puppetlabs", "/etc/puppetlabs/puppet", "/opt/puppetlabs"],
          :results => ["/opt/puppetlabs", "/etc/puppetlabs", "/var/log/puppetlabs"],
        },
        {
          :directories => ["/opt/puppetlabs/bin", "/etc/puppetlabs", "/var/log/puppetlabs", "/etc/puppetlabs/puppet", "/opt/puppetlabs/lib"],
          :results => ["/opt/puppetlabs/bin", "/etc/puppetlabs", "/var/log/puppetlabs", "/opt/puppetlabs/lib"],
        },
      ]
    end

    it 'returns only the highest level directories' do
      test_sets.each do |set|
        expect(component).to receive(:directories).and_return([])


        cur_plat.instance_eval('platform "el-7-x86_64" do |plat| end')
        proj = Vanagon::Project::DSL.new('test-fixture', cur_plat._platform)
        proj.instance_eval(project_block)

        set[:directories].each {|dir| proj.directory dir }
        expect(proj._project.get_root_directories.sort).to eq(set[:results].sort)
      end
    end
  end
end
