require 'makefile'

describe Makefile::Rule do
  describe "a rule with no dependencies and an empty recipe" do
    subject { described_class.new("empty") }

    it "creates an empty rule" do
      expect(subject.format).to eq "empty: export VANAGON_TARGET := empty\nempty:\n"
    end
  end

  describe "a rule with no dependencies and a simple recipe" do
    subject { described_class.new("simple", recipe: ["touch simple"]) }

    it "creates the rule with the recipe" do
      expect(subject.format).to eq "simple: export VANAGON_TARGET := simple\nsimple:\n\ttouch simple\n"
    end
  end

  describe "a rule with dependencies and no recipe" do
    subject { described_class.new("depends", dependencies: ["mydeps"]) }

    it "creates the rule with the recipe" do
      expect(subject.format).to eq "depends: export VANAGON_TARGET := depends\ndepends: mydeps\n"
    end
  end

  describe "a rule with dependencies and a recipe" do
    subject { described_class.new("deluxe", recipe: ["touch deluxe"], dependencies: ["mydeps"]) }

    it "creates the rule with the recipe" do
      expect(subject.format).to eq "deluxe: export VANAGON_TARGET := deluxe\ndeluxe: mydeps\n\ttouch deluxe\n"
    end
  end

  describe "a rule with a multiline recipe" do
    subject do
      described_class.new("multiline") do |rule|
        rule.recipe = [
          "[ -d build ] || mkdir -p build",
          "cd build &&\ncmake .. &&\nmake &&\nmake install"
        ]
      end
    end

    it "inserts tabs after each newline in the recipe" do
      expect(subject.format).to eq "multiline: export VANAGON_TARGET := multiline\nmultiline:\n\t[ -d build ] || mkdir -p build\n\tcd build &&\n\tcmake .. &&\n\tmake &&\n\tmake install\n"
    end
  end
end
