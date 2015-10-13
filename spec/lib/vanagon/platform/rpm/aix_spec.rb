require 'vanagon/platform'

describe "Vanagon::Platform::RPM::AIX" do
  let(:block) {
    %Q[ platform "aix-5.3-ppc" do |plat|
    end
    ]
  }
  let(:plat) { Vanagon::Platform::DSL.new('aix-5.3-ppc') }

  before do
    plat.instance_eval(block)
  end

  describe '#rpm_defines' do
    it "doesn't include dist on aix" do
      expect(plat._platform.rpm_defines).to_not include('dist')
    end
  end

  describe "aix puts commands in weird places" do
    it "uses /opt/freeware/bin everwhere" do
      ['tar', 'patch', 'install'].each do |cmd|
        expect(plat._platform.send(cmd.to_sym)).to eq(File.join('/opt/freeware/bin', cmd))
      end
    end
  end
end

