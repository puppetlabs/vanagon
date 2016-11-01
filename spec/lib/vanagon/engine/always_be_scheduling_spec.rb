require 'vanagon/engine/always_be_scheduling'
require 'vanagon/driver'
require 'vanagon/platform'
require 'logger'

class Vanagon
  class Driver
    @@logger = Logger.new('/dev/null')
  end
end

describe 'Vanagon::Engine::AlwaysBeScheduling' do
  let (:platform) {
    plat = Vanagon::Platform::DSL.new('aix-6.1-ppc')
    plat.instance_eval("platform 'aix-6.1-ppc' do |plat|
                      plat.build_host 'abcd'
                    end")
    plat._platform
  }

  let (:platform_with_vmpooler_template) {
    plat = Vanagon::Platform::DSL.new('ubuntu-10.04-amd64 ')
    plat.instance_eval("platform 'aix-6.1-ppc' do |plat|
                      plat.build_host 'abcd'
                      plat.vmpooler_template 'ubuntu-1004-amd64'
                    end")
    plat._platform
  }

  let (:platform_with_abs_resource_name) {
    plat = Vanagon::Platform::DSL.new('aix-6.1-ppc')
    plat.instance_eval("platform 'aix-6.1-ppc' do |plat|
                      plat.build_host 'abcd'
                      plat.abs_resource_name 'aix-61-ppc'
                    end")
    plat._platform
  }

  let (:platform_with_both) {
    plat = Vanagon::Platform::DSL.new('aix-6.1-ppc')
    plat.instance_eval("platform 'aix-6.1-ppc' do |plat|
                      plat.build_host 'abcd'
                      plat.vmpooler_template 'aix-six-one-ppc'
                      plat.abs_resource_name 'aix-61-ppc'
                    end")
    plat._platform
  }

  describe '#validate_platform' do
    it 'returns true if the platform has the required attributes' do
      expect(Vanagon::Engine::AlwaysBeScheduling.new(platform, nil).validate_platform)
        .to be(true)
    end
  end

  describe '#build_host_name' do
    it 'by default returns the platform name with no translation' do
      expect(Vanagon::Engine::AlwaysBeScheduling.new(platform, nil).build_host_name)
        .to eq("aix-6.1-ppc")
    end

    it 'returns vmpooler_template if vmpooler_template is specified' do
      expect(Vanagon::Engine::AlwaysBeScheduling.new(platform_with_vmpooler_template, nil).build_host_name)
        .to eq("ubuntu-1004-amd64")
    end

    it 'returns abs_resource_name if abs_resource_name is specified' do
      expect(Vanagon::Engine::AlwaysBeScheduling.new(platform_with_abs_resource_name, nil).build_host_name)
        .to eq("aix-61-ppc")
    end

    it 'prefers abs_resource_name to vmpooler_template if both are specified' do
      expect(Vanagon::Engine::AlwaysBeScheduling.new(platform_with_both, nil).build_host_name)
        .to eq("aix-61-ppc")
    end
  end

  describe '#name' do
    it 'returns "always_be_scheduling" engine name' do
      expect(Vanagon::Engine::AlwaysBeScheduling.new(platform, nil).name)
        .to eq('always_be_scheduling')
    end
  end
end
