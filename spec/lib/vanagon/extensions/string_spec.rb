require 'vanagon/extensions/string'

describe "String" do
  it "responds to #undent" do
    expect(String.new.respond_to?(:undent)).to eq(true)
  end
end

describe "Vanagon::Extensions::String" do
  let (:basic_indented_string) { "\s\sa string" }
  let (:basic_string) { "a string" }
  let (:fancy_indented_string) { "\s\sleading line\n\s\s\s\s\s\strailing line\n\s\s\s\slast line" }
  let (:fancy_string) { "leading line\n    trailing line\n  last line" }
  let (:tab_indented_string) { "\t\t\ttab string" }
  let (:tab_string) { "tab string" }

  describe "#undent" do
    it "trims trivial leading whitespace" do
      expect(basic_indented_string.undent).to eq(basic_string)
    end

    it "trims more complex whitespace" do
      expect(fancy_indented_string.undent).to eq(fancy_string)
    end

    it "trims leading tabs" do
      expect(tab_indented_string.undent).to eq(tab_string)
    end
  end
end
