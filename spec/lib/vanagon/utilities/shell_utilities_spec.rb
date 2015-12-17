require 'vanagon/utilities/shell_utilities'

describe Vanagon::Utilities::ShellUtilities do
  describe "#cmdjoin" do
    it "returns a single value as-is" do
      expect(described_class.cmdjoin(["make test"], " !! ")).to eq "make test"
    end

    it "turns an array with a single value into the wrapped value" do
      expect(described_class.cmdjoin([["make test"]], " !! ")).to eq "make test"
    end

    it "joins multiple commands with the separator string" do
      expect(described_class.cmdjoin(["cd build", "cmake ..", "make"], " !! ")).to eq "cd build !! cmake .. !! make"
    end

    it "joins single strings and arrays of strings" do
      expect(described_class.cmdjoin([
        "cd build",
        ["make", "make test"]
      ], " !! ")).to eq "cd build !! make !! make test"
    end
  end

  it "#andand joins commands with &&" do
    expect(described_class.andand("foo", ["bar", "baz"])).to eq "foo && bar && baz"
  end

  it "#andand_multiline joins commands with && and an escaped newline" do
    expect(described_class.andand_multiline("foo", ["bar", "baz"])).to eq "foo && \\\nbar && \\\nbaz"
  end
end
