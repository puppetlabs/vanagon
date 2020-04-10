require 'vanagon/utilities'
require 'tmpdir'

describe "Vanagon::Utilities" do
  before :each do
    # suppress `#warn` output during tests
    allow(Vanagon::Utilities).to receive(:warn)
  end

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

    it 'finds commands with file extensions' do
      # Set PATHEXT so we can test this outside of windows
      orig_pathext = ENV['PATHEXT']
      ENV['PATHEXT'] = '.COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH;.MSC;.CPL'
      extensions = ENV['PATHEXT'].split(';')

      # take a random element from path for testing
      test_path = ENV['PATH'].split(File::PATH_SEPARATOR).sample
      expect(FileTest).to receive(:executable?).with(File.join(test_path, "#{command}.VBS")).and_return(true)

      # have an `allow` for the negative cases so rspec doesn't fail with unexpected
      # function calls
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path_elem|
        allow(FileTest).to receive(:executable?).with(File.join(path_elem, command))
        extensions.each do |ext|
          allow(FileTest).to receive(:executable?).with(File.join(path_elem, "#{command}#{ext}"))
        end
      end

      expect(Vanagon::Utilities.find_program_on_path(command)).to eq(File.join(test_path, "#{command}.VBS"))
      ENV['PATHEXT'] = orig_pathext
    end
  end

  describe '#local_command' do
    it 'runs commands in an unpolluted environment' do
      cmd = lambda { |arg| %(echo 'if [ "$#{arg}" = "" ]; then exit 0; else exit 1; fi' | /bin/sh) }
      vars = %w(BUNDLE_BIN_PATH BUNDLE_GEMFILE)
      vars.each do |var|
        Vanagon::Utilities.local_command(cmd.call(var))
        expect($?.exitstatus).to eq(0)
      end
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

    it 'adds the correct flags to the command if VANAGON_SSH_AGENT is set' do
      expect(Vanagon::Utilities).to receive(:find_program_on_path).with('ssh').and_return('/tmp/ssh')
      ENV['VANAGON_SSH_AGENT'] = 'true'
      expect(Vanagon::Utilities.ssh_command).to include('-o ForwardAgent=yes')
      ENV['VANAGON_SSH_AGENT'] = nil
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
      expect{ Vanagon::Utilities.retry_with_timeout(tries, timeout) { Vanagon::Utilities.remote_ssh_command(host, command, port) } }.to raise_error(RuntimeError)
    end

    it 'returns true if the command succeeds within n times' do
      expect(Vanagon::Utilities).to receive(:remote_ssh_command).with(host, command, port).exactly(tries - 1).times.and_raise(RuntimeError)
      expect(Vanagon::Utilities).to receive(:remote_ssh_command).with(host, command, port).exactly(1).times.and_return(true)
      expect(Vanagon::Utilities.retry_with_timeout(tries, timeout) { Vanagon::Utilities.remote_ssh_command(host, command, port) }).to be(true)
    end

    it 'raises a Vanagon::Error if the command times out' do
      expect{ Vanagon::Utilities.retry_with_timeout(tries, timeout) { sleep 5 }.to raise_error(Vanagon::Error) }
    end
  end
end
