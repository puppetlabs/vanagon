require 'vanagon/driver'
require 'vanagon/project'
require 'vanagon/platform'

describe 'Vanagon::Driver' do
  let (:project) { double(:project, :settings => {} ) }

  let (:redhat) do
    eval_platform('el-7-x86_64', <<-END)
      platform 'el-7-x86_64' do |plat|
        plat.vmpooler_template 'centos-7-x86_64'
      end
    END
  end

  let(:explicit_workdir){ Dir.mktmpdir }
  let(:explicit_remote_workdir){ Dir.mktmpdir }

  def eval_platform(name, definition)
    plat = Vanagon::Platform::DSL.new(name)
    plat.instance_eval(definition)
    plat._platform
  end

  def create_driver(platform, options = {})
    allow(Vanagon::Project).to receive(:load_project).and_return(project)
    allow(Vanagon::Platform).to receive(:load_platform).and_return(platform)

    Vanagon::Driver.new(platform, project, options)
  end

  describe 'when resolving build host info' do
    it 'uses an expicitly specified workdir if provided' do
      derived = create_driver(redhat)
      explicit = create_driver(redhat, workdir: explicit_workdir)

      expect(explicit.workdir).to eq(explicit_workdir)
      expect(explicit.workdir).not_to eq(derived.workdir)
    end

    it 'uses an expicitly specified remote workdir if provided' do
      derived = create_driver(redhat)
      explicit = create_driver(redhat, remote_workdir: explicit_remote_workdir)

      expect(explicit.remote_workdir).to eq(explicit_remote_workdir)
      expect(explicit.remote_workdir).not_to eq(derived.remote_workdir)
    end

    it 'returns the vmpooler_template using the pooler engine' do
      info = create_driver(redhat).build_host_info

      expect(info).to match({ 'name'   => 'centos-7-x86_64',
                              'engine' => 'pooler' })
    end

    it 'returns the vmpooler template with an explicit engine' do
      info = create_driver(redhat, :engine => 'pooler').build_host_info

      expect(info).to match({ 'name'   => 'centos-7-x86_64',
                              'engine' => 'pooler' })
    end

    it 'returns the first build_host using the hardware engine' do
      platform = eval_platform('aix-7.1-ppc', <<-END)
        platform 'aix-7.1-ppc' do |plat|
          plat.build_host ["pe-aix-71-01", "pe-aix-71-02"]
        end
      END

      info = create_driver(platform).build_host_info

      expect(info).to match({ 'name'   => 'pe-aix-71-01',
                              'engine' => 'hardware' })
    end

    it 'returns the first build_host using the hardware engine when not using an engine, and not specifying an engine in the platform configuration' do
      platform = eval_platform('aix-7.1-ppc', <<-END)
        platform 'aix-7.1-ppc' do |plat|
          plat.build_host ["pe-aix-71-01", "pe-aix-71-02"]
        end
      END

      info = create_driver(platform).build_host_info

      expect(info).to match({ 'name'   => 'pe-aix-71-01',
                              'engine' => 'hardware' })
    end

    it 'returns the platform and the always_be_scheduling engine when using the always_be_scheduling engine' do
      platform = eval_platform('aix-7.1-ppc', <<-END)
        platform 'aix-7.1-ppc' do |plat|
          plat.build_host ["pe-aix-71-01", "pe-aix-71-02"]
        end
      END

      info = create_driver(platform, :engine => 'always_be_scheduling').build_host_info

      expect(info).to match({ 'name'   => 'aix-7.1-ppc',
                              'engine' => 'always_be_scheduling' })
    end

    it 'returns the vmpooler_template using the always_be_scheduling engine when using the always_be_scheduling engine' do
      info = create_driver(redhat, :engine => 'always_be_scheduling').build_host_info

      expect(info).to match({ 'name'   => 'centos-7-x86_64',
                              'engine' => 'always_be_scheduling' })
    end

    it 'returns the docker_image using the docker engine' do
      platform = eval_platform('el-7-x86_64', <<-END)
        platform 'el-7-x86_64' do |plat|
          plat.docker_image 'centos7'
        end
      END

      expect(Vanagon::Utilities).to receive(:find_program_on_path).with('docker').and_return('/usr/bin/docker')
      info = create_driver(platform, :engine => 'docker').build_host_info

      expect(info).to match({ 'name'   => 'centos7',
                              'engine' => 'docker' })
    end

    it 'returns "local machine" using the local engine' do
      info = create_driver(redhat, :engine => 'local').build_host_info

      expect(info).to match({ 'name'   => 'local machine',
                              'engine' => 'local' })
    end

    it 'raises when using the base engine' do
      driver = create_driver(redhat, :engine => 'base')

      expect {
        driver.build_host_info
      }.to raise_error(Vanagon::Error,
                       /build_host_name has not been implemented for your engine/)
    end
  end
end
