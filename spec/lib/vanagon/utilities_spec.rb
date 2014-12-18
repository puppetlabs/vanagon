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
end
