require 'vanagon/engine/pooler'
require 'vanagon/platform'

describe 'Vanagon::Engine::Pooler' do
  let (:platform) { double(Vanagon::Platform, :target_user => 'root') }
  let (:platform_with_vcloud_name) {
    plat = Vanagon::Platform::DSL.new('debian-6-i386')
    plat.instance_eval("platform 'debian-6-i386' do |plat|
                      plat.vcloud_name 'debian-6-i386'
                    end")
    plat._platform
  }

  let (:platform_without_vcloud_name) {
    plat = Vanagon::Platform::DSL.new('debian-6-i386')
    plat.instance_eval("platform 'debian-6-i386' do |plat|
                    end")
    plat._platform
  }

  before :each do
    # suppress `#warn` output during tests
    allow_any_instance_of(Vanagon::Platform::DSL).to receive(:warn)

    # stubbing ENV doesn't actually intercept ENV because ENV
    # is special and you aren't. So we have to mangle the value
    # of ENV around each of these tests if we want to prevent
    # actual user credentials from being loaded, or attempt to
    # validate the way that credentials are read.
    ENV['REAL_HOME'] = ENV.delete 'HOME'
    ENV['REAL_VMPOOLER_TOKEN'] = ENV.delete 'VMPOOLER_TOKEN'
    ENV['HOME'] = Dir.mktmpdir

    # This should help maintain the ENV['HOME'] masquerade
    allow(Dir).to receive(:home).and_return(ENV['HOME'])
  end

  after :each do
    # Altering ENV directly is a legitimate code-smell.
    # We should at least clean up after ourselves.
    ENV['HOME'] = ENV.delete 'REAL_HOME'
    ENV['VMPOOLER_TOKEN'] = ENV.delete 'REAL_VMPOOLER_TOKEN'
  end

  # We don't want to run the risk of reading legitimate user
  # data from a user who is unfortunate enough to be running spec
  # tests on their local machine. This means we have to intercept
  # and stub out a very specific environment, where:
  #   1) an environment variable exists
  #   2) the env. var is unset, and only a ~/.vmpooler-token file exists
  #   3) the env. var is unset, and only a ~/.vmfloaty.yml file exists
  describe "#load_token" do
    let(:environment_value) { 'cafebeef' }
    let(:token_value) { 'decade' }
    let(:pooler_token_file) { File.expand_path('~/.vanagon-token') }
    let(:floaty_config) { File.expand_path('~/.vmfloaty.yml') }

    it 'prefers the VMPOOLER_TOKEN environment variable to a config file' do
      allow(ENV).to receive(:[])
                      .with('VMPOOLER_TOKEN')
                      .and_return(environment_value)

      expect(Vanagon::Engine::Pooler.new(platform).token)
        .to_not eq(token_value)

      expect(Vanagon::Engine::Pooler.new(platform).token)
        .to eq(environment_value)
    end

    it %(reads a token from '~/.vanagon-token' if the environment variable is not set) do
      allow(File).to receive(:exist?)
                      .with(pooler_token_file)
                      .and_return(true)

      allow(File).to receive(:read)
                      .with(pooler_token_file)
                      .and_return(token_value)

      expect(Vanagon::Engine::Pooler.new(platform).token)
        .to eq(token_value)
    end

    it %(reads a token from '~/.vmfloaty.yml' if '~/.vanagon-token' doesn't exist) do
      allow(File).to receive(:exist?)
                      .with(pooler_token_file)
                      .and_return(false)

      allow(File).to receive(:exist?)
                      .with(floaty_config)
                      .and_return(true)

      allow(YAML).to receive(:load_file)
                      .with(floaty_config)
                      .and_return({'token' => token_value})

      expect(Vanagon::Engine::Pooler.new(platform).token).to eq(token_value)
    end

    it %(returns 'nil' if no vmpooler token configuration exists) do
      allow(File).to receive(:exist?)
                      .with(pooler_token_file)
                      .and_return(false)

      allow(File).to receive(:exist?)
                      .with(floaty_config)
                      .and_return(false)

      expect(Vanagon::Engine::Pooler.new(platform).token).to be_nil
    end
  end

  describe "#validate_platform" do
    it 'raises an error if the platform is missing a required attribute' do
      expect{ Vanagon::Engine::Pooler.new(platform_without_vcloud_name).validate_platform }.to raise_error(Vanagon::Error)
    end

    it 'returns true if the platform has the required attributes' do
      expect(Vanagon::Engine::Pooler.new(platform_with_vcloud_name).validate_platform).to be(true)
    end
  end

  it 'returns "pooler" name' do
    expect(Vanagon::Engine::Pooler.new(platform_with_vcloud_name).name).to eq('pooler')
  end
end
