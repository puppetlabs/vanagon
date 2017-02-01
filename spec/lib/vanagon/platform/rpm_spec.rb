require 'vanagon/platform'

describe 'Vanagon::Platform::RPM' do
  platforms = [
    { name: 'el-5-i386' },
    { name: 'fedora-21-x86_64', dist: 'f21' },
    { name: 'cisco-wrlinux-7-x86_64' }
  ]

  platforms.each do |platform|
    context "defines RPM-based platform attributes for #{platform[:name]}" do
      subject {
        plat = Vanagon::Platform::DSL.new(platform[:name])
        plat.instance_eval(%(platform("#{platform[:name]}") { |plat| }))
        plat._platform.dist = platform[:dist]
        plat._platform
      }

      let(:derived_dist) { subject.os_name.tr('-', '_') + subject.os_version }
      let(:dist) { platform[:dist] || derived_dist }
      let(:defined_dist) { "--define 'dist .#{dist}'" }

      describe '#rpm_defines' do
        it "includes the expected 'dist' defines" do
          expect(subject.rpm_defines).to include(defined_dist)
        end
      end

      describe "#dist" do
        it "uses explicit values when available" do
          expect(subject.dist).to eq(derived_dist) unless platform[:dist]
          expect(subject.dist).to eq(dist)
        end
      end
    end
  end
end
