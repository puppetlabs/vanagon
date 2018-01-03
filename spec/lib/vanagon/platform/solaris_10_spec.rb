require 'vanagon/platform'

describe "Vanagon::Platform::Solaris10" do
  let(:block) {
    %Q[ platform "solaris-10-i386" do |plat|
    end
    ]
  }
  let(:plat) { Vanagon::Platform::DSL.new('solaris-10-i386') }

  before do
    plat.instance_eval(block)
  end

  describe "solaris10 has weird paths for gnu commands" do
    it "has some in /opt/csw/bin" do
      ['make', 'sed'].each do |cmd|
        expect(plat._platform.send(cmd.to_sym)).to eq(File.join('/opt/csw/bin', "g#{cmd}"))
      end
    end
    it "uses /usr/sfw/bin/gtar" do
      expect(plat._platform.send(:tar)).to eq('/usr/sfw/bin/gtar')
    end
    it "uses /usr/bin/gpatch" do
      expect(plat._platform.send(:patch)).to eq('/usr/bin/gpatch')
    end
  end
end

