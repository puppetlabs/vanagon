require 'vanagon/engine/docker'
require 'vanagon/platform'

describe Vanagon::Engine::Docker do
  before(:each) do
    allow(Vanagon::Utilities).to receive(:find_program_on_path).with('docker').and_return('/usr/bin/docker')
  end

  let (:platform_with_docker_image) do
    plat = Vanagon::Platform::DSL.new('debian-10-amd64')
    plat.instance_eval(<<~EOF)
      platform 'debian-10-amd64' do |plat|
        plat.docker_image 'debian:10-slim'
      end
    EOF
    plat._platform
  end

  let (:platform_without_docker_image) do
    plat = Vanagon::Platform::DSL.new('debian-10-amd64')
    plat.instance_eval(<<~EOF)
      platform 'debian-10-amd64' do |plat|
      end
    EOF
    plat._platform
  end

  let(:platform_with_docker_exec) do
    plat = Vanagon::Platform::DSL.new('debian-10-amd64')
    plat.instance_eval(<<~EOF)
      platform 'debian-10-amd64' do |plat|
        plat.docker_image 'debian:10-slim'
        plat.use_docker_exec true
      end
    EOF
    plat._platform
  end

  describe '#initialize' do
    it 'fails without docker installed' do
      allow(Vanagon::Utilities).to receive(:find_program_on_path).with('docker').and_call_original
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path_elem|
        expect(FileTest).to receive(:executable?).with(File.join(path_elem, 'docker')).and_return(false)
      end

      expect { described_class.new(platform_with_docker_image) }.to raise_error(RuntimeError)
    end
  end

  describe "#validate_platform" do
    it 'raises an error if the platform is missing a required attribute' do
      expect { described_class.new(platform_without_docker_image).validate_platform }.to raise_error(Vanagon::Error)
    end

    it 'returns true if the platform has the required attributes' do
      expect(described_class.new(platform_with_docker_image).validate_platform).to be(true)
    end
  end

  it 'returns "docker" name' do
    expect(described_class.new(platform_with_docker_image).name).to eq('docker')
  end

  describe '#dispatch' do
    context 'when platform has use_docker_exec set' do
      subject { described_class.new(platform_with_docker_exec) }

      it 'uses docker exec' do
        expect(Vanagon::Utilities).to receive(:remote_ssh_command).never
        expect(subject).to receive(:docker_exec)

        subject.dispatch('true', true)
      end
    end
  end

  describe '#ship_workdir' do
    context 'when platform has use_docker_exec set' do
      subject { described_class.new(platform_with_docker_exec) }

      it 'uses docker cp' do
        expect(Vanagon::Utilities).to receive(:rsync_to).never
        expect(subject).to receive(:docker_cp_globs_to)

        subject.ship_workdir('foo/')
      end
    end
  end

  describe '#retrieve_built_artifact' do
    context 'when platform has use_docker_exec set' do
      subject { described_class.new(platform_with_docker_exec) }

      before(:each) do
        allow(FileUtils).to receive(:mkdir_p)
      end

      it 'uses docker cp' do
        expect(Vanagon::Utilities).to receive(:rsync_from).never
        expect(subject).to receive(:docker_cp_globs_from)

        subject.retrieve_built_artifact('output/*', false)
      end
    end
  end

  describe '#select_target' do
    context 'when platform has use_docker_exec set' do
      subject { described_class.new(platform_with_docker_exec) }

      it 'starts a new docker instance' do
        expect(Vanagon::Utilities).to receive(:ex).with("/usr/bin/docker run -d --name debian_10-slim-builder   debian:10-slim")

        subject.select_target
      end

      it 'sets the target to a localhost URI' do
        allow(Vanagon::Utilities).to receive(:ex)

        subject.select_target

        uri = subject.target
        expect(uri).to be_an_instance_of(URI::Generic)
        expect(uri.path).to eq('localhost')
      end
    end
  end
end
