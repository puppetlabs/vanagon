require 'vanagon/environment'

describe "Vanagon::Environment" do
  before :all do
    @good_names = %w(name _name NAME _NAME NAME123 _123NAME)
    @bad_names = ['no-name', '!name', '.name', '123name_', 1, '-name']
    @good_values =[
      'valuable',
      'most\ valuable',
      'extremely-valuable',
      'VALUE_BEYOND_MEASURE',
      2004,
      2007,
    ]
    @bad_values = [
      'string with literal spaces',
      %w(an array of strings),
      19.81,
      Object.new,
      Tempfile.new('captain_planet'),
      lambda { |x| "#{x}" }
    ]

    @good_hash = @good_names.zip(@good_values.shuffle).to_h
    @bad_hash = @bad_names.zip(@bad_values.shuffle).to_h

    @good_names_bad_values = @good_names.zip(@bad_values.shuffle).to_h
    @bad_names_good_values = @bad_names.zip(@good_values.shuffle).to_h
  end

  before :each do
    @local_env = Vanagon::Environment.new
  end

  describe "#[]" do
    before do
      @key = @good_names.sample
      @value = @good_values.sample
      @local_env[@key] = @value
    end

    it "returns values for matching keys" do
      expect(@local_env[@key])
        .to eq(@value)
    end
  end

  describe "#[]=" do
    it "accepts and assigns valid keys and values" do
      @good_hash.each_pair do |key, value|
        expect { @local_env[key] = value }
            .to_not raise_error
      end
    end

    it "raises an ArgumentError for invalid keys" do
      @bad_names_good_values.each_pair do |key, value|
          expect { @local_env[key] = value }
            .to raise_error(ArgumentError)
      end
    end

    it "raises an ArgumentError for invalid values" do
      @good_names_bad_values.each_pair do |key, value|
          expect { @local_env[key] = value }
            .to raise_error(ArgumentError)
      end
    end
  end

  describe "#keys" do
    before do
      @good_hash.each_pair do |key, value|
        @local_env[key] = value
      end
    end

    it "returns an array of all keys in a populated Environment" do
      # This is a little bit of a shell game. Array comparisons in Ruby rely
      # on the order of the elements, not just the contents of the array.
      # By randomizing our element order going in, and then using a set
      # intersection (#&) and sorting the output, we can then compare the
      # intersection against our sorted control group (@good_names).
      # That should shake out if we have too many or too few keys.
      expect(
        (@local_env.keys.shuffle & @good_names.shuffle).sort
      ).to eq(@good_names.sort)
    end
  end

  describe "#values" do
    before do
      @good_hash.each_pair do |key, value|
        @local_env[key] = value
      end
    end

    it "returns an array of all values in a populated Environment" do
      # Same "juggle some values" dance as #keys, except that #values
      # may contain Integers or Strings and they are not directly comparable.
      # We'll compare the hashed values of each element in the returned array
      # against the hashed value of each element in the expected array instead.
      expect(
        (@local_env.values.shuffle & @good_values.shuffle)
          .sort { |x, y| x.hash <=> y.hash }
        ).to eq(@good_values.sort { |x, y| x.hash <=> y.hash })
    end
  end

  describe "#merge" do
    before do
      @new_env = Vanagon::Environment.new
      @new_env['__merge'] = "true"
      @merged_values = @local_env.values + @new_env.values
      @merged_keys = @local_env.keys + @new_env.keys
      @merged_env = @local_env.merge(@new_env)
    end

    it "returns a new Environment Object" do
      expect(@local_env.merge(@new_env).equal? @local_env)
        .to be false
    end

    it "combines the keys of both Environments" do
      expect(@merged_env.keys.sort { |x, y| x.hash <=> y.hash })
        .to eq(@merged_keys.sort { |x, y| x.hash <=> y.hash })
    end

    it "combines the values of both Environments" do
      expect(@merged_env.values.sort { |x, y| x.hash <=> y.hash })
        .to eq(@merged_values.sort { |x, y| x.hash <=> y.hash })
    end
  end

  describe "#merge!" do
    before do
      @new_env = Vanagon::Environment.new
      @new_env['__merge'] = "true"
      @merged_values = @local_env.values + @new_env.values
      @merged_keys = @local_env.keys + @new_env.keys
      @local_obj_id = @local_env.object_id
    end

    before do
      @local_env.merge! @new_env
    end

    it "does not create a new Environment Object" do
      expect(@local_env.object_id == @local_obj_id)
        .to be true
    end

    it "combines the keys of both Environments" do
      expect(@local_env.keys.sort { |x, y| x.hash <=> y.hash })
        .to eq(@merged_keys.sort { |x, y| x.hash <=> y.hash })
    end

    it "combines the values of both Environments" do
      expect(@local_env.values.sort { |x, y| x.hash <=> y.hash })
        .to eq(@merged_values.sort { |x, y| x.hash <=> y.hash })
    end
  end

  describe "#to_a" do
    it "converts an Environment to an Array of Strings" do
      expect(@local_env.to_a.select { |v| v.is_a? String }.sort)
        .to eq(@local_env.to_a.sort)
    end
  end

  describe "#to_s" do
    it "correctly converts an Environment to a String" do
      expect(@local_env.to_s.shellsplit)
        .to eq(@local_env.to_a)
    end
  end
end
