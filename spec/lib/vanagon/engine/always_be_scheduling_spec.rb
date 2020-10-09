require 'vanagon/engine/always_be_scheduling'
require 'vanagon/driver'
require 'vanagon/platform'
require 'logger'
require 'spec_helper'

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
  let(:pooler_token_file) { File.expand_path('~/.vanagon-token') }
  let(:floaty_config) { File.expand_path('~/.vmfloaty.yml') }

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

  describe '#read_vanagon_token' do
    it 'takes the first line for abs token, second line is optional' do
      token_value = 'decade'
      allow(File).to receive(:exist?)
                         .with(pooler_token_file)
                         .and_return(true)

      allow(File).to receive(:read)
                         .with(pooler_token_file)
                         .and_return(token_value)

      abs_service = Vanagon::Engine::AlwaysBeScheduling.new(platform, nil)
      expect(abs_service.token).to eq('decade')
      expect(abs_service.token_vmpooler).to eq(nil)
    end
    it 'takes the second line as vmpooler token' do
      token_value = "decade\nanddaycade"
      allow(File).to receive(:exist?)
                         .with(pooler_token_file)
                         .and_return(true)

      allow(File).to receive(:read)
                         .with(pooler_token_file)
                         .and_return(token_value)

      abs_service = Vanagon::Engine::AlwaysBeScheduling.new(platform, nil)
      expect(abs_service.token).to eq('decade')
      expect(abs_service.token_vmpooler).to eq('anddaycade')
    end
  end

  describe '#read_vmfloaty_token' do
    before :each do
      allow(File).to receive(:exist?)
                         .with(pooler_token_file)
                         .and_return(false)

      allow(File).to receive(:exist?)
                         .with(floaty_config)
                         .and_return(true)
    end
    token_value = 'decade'
    it %(reads a token from '~/.vmfloaty.yml at the top level') do
      allow(YAML).to receive(:load_file)
                         .with(floaty_config)
                         .and_return({'token' => token_value})

      abs_service = Vanagon::Engine::AlwaysBeScheduling.new(platform, nil)
      expect(abs_service.token).to eq(token_value)
      expect(abs_service.token_vmpooler).to eq(nil)
    end
    it %(reads a token from '~/.vmfloaty.yml in the abs service') do
      allow(YAML).to receive(:load_file)
                         .with(floaty_config)
                         .and_return({'services' =>
                                          {'MYabs' => {'type'=>'abs', 'token'=>token_value, 'url'=>'foo'}}
                                     })

      abs_service = Vanagon::Engine::AlwaysBeScheduling.new(platform, nil)
      expect(abs_service.token).to eq(token_value)
      expect(abs_service.token_vmpooler).to eq(nil)
    end
    it %(reads a token from '~/.vmfloaty.yml in the abs service and includes the vmpooler token') do
      vmp_token_value = 'deecade'
      allow(YAML).to receive(:load_file)
                         .with(floaty_config)
                         .and_return({'services' =>
                                          {'MYabs' => {'type'=>'abs', 'token'=>token_value, 'url'=>'foo', 'vmpooler_fallback' => 'myvmp'},
                                           'myvmp' => {'token'=>vmp_token_value, 'url'=>'bar'}}
                                     })

      abs_service = Vanagon::Engine::AlwaysBeScheduling.new(platform, nil)
      expect(abs_service.token).to eq(token_value)
      expect(abs_service.token_vmpooler).to eq(vmp_token_value)
    end
  end
  describe '#select_target_from' do
    it 'runs successfully' do
      hostname = 'faint-whirlwind.puppet.com'
      stub_request(:post, "https://foobar/request").
          to_return({status: 202, body: "", headers: {}},{status: 200, body: '[{"hostname":"'+hostname+'","type":"aix-6.1-ppc","engine":"nspooler"}]', headers: {}})
      abs_service = Vanagon::Engine::AlwaysBeScheduling.new(platform, nil)
      abs_service.select_target_from("https://foobar")
      expect(abs_service.target).to eq(hostname)
    end
    it 'returns a warning if the first request is not a 202' do
      hostname = 'fainter-whirlwind.puppet.com'
      stub_request(:post, "https://foobar/request").
          to_return({status: 404, body: "", headers: {}},{status: 200, body: '[{"hostname":"'+hostname+'","type":"aix-6.1-ppc","engine":"nspooler"}]', headers: {}})
      allow_any_instance_of(Object).to receive(:warn)
      expect_any_instance_of(Object).to receive(:warn).with("failed to request ABS with code 404")
      abs_service = Vanagon::Engine::AlwaysBeScheduling.new(platform, nil)
      pooler = abs_service.select_target_from("https://foobar")
      expect(pooler).to eq('')
    end
    it 'returns a warning and retries until request is a 200' do
      hostname = 'faintest-whirlwind.puppet.com'
      stub_request(:post, "https://foobar/request").
          to_return({status: 202, body: "", headers: {}},
                    {status: 503, body: "", headers: {}},
                    {status: 200, body: '[{"hostname":"'+hostname+'","type":"aix-6.1-ppc","engine":"nspooler"}]', headers: {}})
      allow_any_instance_of(Object).to receive(:warn)
      expect_any_instance_of(Object).to receive(:warn).with(/Waiting 1 seconds to check if ABS request has been filled/)
      abs_service = Vanagon::Engine::AlwaysBeScheduling.new(platform, nil)
      abs_service.select_target_from("https://foobar")
      expect(abs_service.target).to eq(hostname)
    end
  end
end