require 'vanagon/component/dsl'
require 'json'

describe 'Vanagon::Component::DSL' do
  let (:component_block) {
"component 'test-fixture' do |pkg, settings, platform|
  pkg.load_from_json('spec/fixures/component/test-fixture.json')
end" }

  let (:invalid_component_block) {
"component 'test-fixture' do |pkg, settings, platform|
  pkg.load_from_json('spec/fixures/component/invalid-test-fixture.json')
end" }

  describe '#load_from_json' do
    it "sets the ref and url based on the json fixture" do
      comp = Vanagon::Component::DSL.new('test-fixture', {}, {})
      comp.instance_eval(component_block)
      expect(comp._component.options[:ref]).to eq('3.7.3')
      expect(comp._component.url).to eq('git@github.com:puppetlabs/puppet')
    end

    it "raises an error on invalid methods/attributes in the json" do
      comp = Vanagon::Component::DSL.new('test-fixture', {}, {})
      expect { comp.instance_eval(invalid_component_block) }.to raise_error(RuntimeError)
    end
  end
end
