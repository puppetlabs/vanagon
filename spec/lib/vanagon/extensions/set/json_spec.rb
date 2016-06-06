require 'vanagon/extensions/set/json'

describe "Set" do
  describe "with JSON mixins" do
    let(:test_set) { Set['a', 'a', 'b', 'c'] }
    let(:json_set) { %(["a","b","c"]) }

    it "responds to #to_json" do
      expect(Set.new.respond_to?(:to_json)).to eq(true)
    end

    it "can be converted to a valid JSON object" do
      expect(JSON.parse(test_set.to_json)).to eq(JSON.parse(json_set))
    end
  end
end

