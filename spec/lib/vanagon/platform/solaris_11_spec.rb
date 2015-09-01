require 'vanagon/platform/solaris_11'

describe "Vanagon::Platform::Solaris_11" do
  let(:platform) do
    {
      :name => 'solaris-11-i386',
      :block => %Q[platform "solaris-11-i386" do |plat| end]
    }
  end

  let(:versions) do
    [
      # Leading and trailing - stripped
      { :original => "-1.2.3-", :final => "1.2.3" },

      # Non-numeric stripped
      { :original => "-1.2bcd.3aaz-", :final => "1.2.3" },

      # Leading, non-singular zeroes stripped
      { :original => "1.0.2.00123", :final => "1.0.2.123" },
      { :original => "1.0000.2.00123", :final => "1.0.2.123" },
    ]
  end

  describe '#ips_version' do
    it 'strips invalid characters from the version' do
      versions.each do |ver|
        plat = Vanagon::Platform::DSL.new(platform[:name])
        plat.instance_eval(platform[:block])
        expect(plat._platform.ips_version(ver[:original])).to eq("#{ver[:final]},5.11-1")
      end
    end
  end
end
