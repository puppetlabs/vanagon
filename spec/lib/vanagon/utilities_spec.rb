require 'vanagon/utilities'
require 'tmpdir'

describe "Vanagon::Utilities" do
  describe "#find_program_on_path" do
    let(:command) { "thingie" }

    it 'finds commands on the PATH' do
      path_elems = ENV['PATH'].split(File::PATH_SEPARATOR)
      path_elems.each_with_index do |path_elem, i|
        expect(FileTest).to receive(:executable?).with(File.join(path_elem, command)).and_return(i == 0)
        break
      end

      expect(Vanagon::Utilities.find_program_on_path(command)).to eq(File.join(path_elems.first, command))
    end

    it 'finds commands on the PATH' do
      path_elems = ENV['PATH'].split(File::PATH_SEPARATOR)
      path_elems.each_with_index do |path_elem, i|
        expect(FileTest).to receive(:executable?).with(File.join(path_elem, command)).and_return(i == path_elems.length - 1)
      end

      expect(Vanagon::Utilities.find_program_on_path(command)).to eq(File.join(path_elems.last, command))
    end

    it 'raises an error if required is true and command is not found' do
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path_elem|
        expect(FileTest).to receive(:executable?).with(File.join(path_elem, command)).and_return(false)
      end

      expect { Vanagon::Utilities.find_program_on_path(command) }.to raise_error(RuntimeError)
    end

    it 'returns false if required is false and command is not found' do
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path_elem|
        expect(FileTest).to receive(:executable?).with(File.join(path_elem, command)).and_return(false)
      end

      expect(Vanagon::Utilities.find_program_on_path(command, false)).to be(false)
    end
  end

  describe "#is_git_repo?" do
    let(:dir) { Dir.mktmpdir }
    after(:each) { FileUtils.rm_rf(dir) }

    it "returns false if not in a git repo" do
      expect(Vanagon::Utilities.is_git_repo?(dir)).to be(false)
    end

    it "returns true if in a git repo" do
      Dir.chdir(dir) do
        Vanagon::Utilities.git('init')
      end

      expect(Vanagon::Utilities.is_git_repo?(dir)).to be(true)
    end
  end

  describe "#git_version" do
    let(:dir) { Dir.mktmpdir }
    after(:each) { FileUtils.rm_rf(dir) }

    it "raises an exception if not in a git repo" do
      expect { Vanagon::Utilities.git_version(dir) }.to raise_error(RuntimeError)
    end

    it "returns a git tag based version if there are tags in the repo" do
      Dir.chdir(dir) do
        Vanagon::Utilities.git('init')
        Vanagon::Utilities.git('commit --allow-empty -m "testing this ish"')
        Vanagon::Utilities.git('tag 1.2.3')
      end

      expect(Vanagon::Utilities.git_version(dir)).to eq('1.2.3')
    end

    it "returns empty string if there are no tags" do
      Dir.chdir(dir) do
        Vanagon::Utilities.git('init')
      end

      expect(Vanagon::Utilities.git_version(dir)).to be_empty
    end
  end

  describe '#ssh_command' do
    it 'adds the correct flags to the command if VANAGON_SSH_KEY is set' do
      expect(Vanagon::Utilities).to receive(:find_program_on_path).with('ssh').and_return('/tmp/ssh')
      ENV['VANAGON_SSH_KEY'] = '/a/b/c'
      expect(Vanagon::Utilities.ssh_command).to include('/tmp/ssh -i /a/b/c')
      ENV['VANAGON_SSH_KEY'] = nil
    end

    it 'returns just the path to ssh if VANAGON_SSH_KEY is not set' do
      expect(Vanagon::Utilities).to receive(:find_program_on_path).with('ssh').and_return('/tmp/ssh')
      expect(Vanagon::Utilities.ssh_command).to include('/tmp/ssh')
    end

    it 'sets the port to 22 when none is specified' do
      expect(Vanagon::Utilities).to receive(:find_program_on_path).with('ssh').and_return('/tmp/ssh')
      expect(Vanagon::Utilities.ssh_command).to include('-p 22')
    end

    it 'sets the port to 2222 when that is specified' do
      expect(Vanagon::Utilities).to receive(:find_program_on_path).with('ssh').and_return('/tmp/ssh')
      expect(Vanagon::Utilities.ssh_command(2222)).to include('-p 2222')
    end

    it 'disables strict host checking' do
      expect(Vanagon::Utilities).to receive(:find_program_on_path).with('ssh').and_return('/tmp/ssh')
      expect(Vanagon::Utilities.ssh_command).to include('-o StrictHostKeyChecking=no')
    end

    it 'sets known hosts file to /dev/null' do
      expect(Vanagon::Utilities).to receive(:find_program_on_path).with('ssh').and_return('/tmp/ssh')
      expect(Vanagon::Utilities.ssh_command).to include('-o UserKnownHostsFile=/dev/null')
    end
  end

  describe '#retry_with_timeout' do
    let (:tries) { 7 }
    let (:timeout) { 2 }
    let (:host) { 'abcd' }
    let (:command) { 'echo' }
    let (:port) { 1234 }

    it 'raises a Vanagon::Error if the command fails n times' do
      expect(Vanagon::Utilities).to receive(:remote_ssh_command).with(host, command, port).exactly(tries).times.and_raise(RuntimeError)
      expect{ Vanagon::Utilities.retry_with_timeout(tries, timeout) { Vanagon::Utilities.remote_ssh_command(host, command, port) } }.to raise_error(Vanagon::Error)
    end

    it 'returns true if the command succeeds within n times' do
      expect(Vanagon::Utilities).to receive(:remote_ssh_command).with(host, command, port).exactly(tries - 1).times.and_raise(RuntimeError)
      expect(Vanagon::Utilities).to receive(:remote_ssh_command).with(host, command, port).exactly(1).times.and_return(true)
      expect(Vanagon::Utilities.retry_with_timeout(tries, timeout) { Vanagon::Utilities.remote_ssh_command(host, command, port) }).to be(true)
    end
  end
end
