require 'vanagon/extensions/ostruct/json'

describe "OpenStruct" do
  describe "with JSON mixins" do
    let(:test_ostruct) { OpenStruct.new(size: "big", shape: "spherical", name: "rover") }
    let(:json_ostruct) { %({"size":"big","shape":"spherical","name":"rover"}) }

    it "responds to #to_json" do
      expect(OpenStruct.new.respond_to?(:to_json)).to eq(true)
    end

    it "can be converted to a valid JSON object" do
      expect(JSON.parse(test_ostruct.to_json)).to eq(JSON.parse(json_ostruct))
    end
  end
end
