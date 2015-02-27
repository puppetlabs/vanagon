require 'vanagon/engine/docker'

describe 'Vanagon::Engine::Docker' do
  let (:platform_with_docker_image) {
    plat = Vanagon::Platform::DSL.new('debian-6-i386')
    plat.instance_eval("platform 'debian-6-i386' do |plat|
                      plat.docker_image 'debian-6-i386'
                    end")
    plat._platform
  }

  let (:platform_without_docker_image) {
    plat = Vanagon::Platform::DSL.new('debian-6-i386')
    plat.instance_eval("platform 'debian-6-i386' do |plat|
                    end")
    plat._platform
  }

  describe '#initialize' do
    it 'fails without docker installed' do
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path_elem|
        expect(FileTest).to receive(:executable?).with(File.join(path_elem, 'docker')).and_return(false)
      end

      expect { Vanagon::Engine::Docker.new(platform_with_docker_image) }.to raise_error(RuntimeError)
    end
  end

  describe "#validate_platform" do
    it 'raises an error if the platform is missing a required attribute' do
      expect(Vanagon::Utilities).to receive(:find_program_on_path).with('docker').and_return('/usr/bin/docker')
      expect { Vanagon::Engine::Docker.new(platform_without_docker_image).validate_platform }.to raise_error(Vanagon::Error)
    end

    it 'returns true if the platform has the required attributes' do
      expect(Vanagon::Utilities).to receive(:find_program_on_path).with('docker').and_return('/usr/bin/docker')
      expect(Vanagon::Engine::Docker.new(platform_with_docker_image).validate_platform).to be(true)
    end
  end
end
