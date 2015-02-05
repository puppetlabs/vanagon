require 'vanagon/common/pathname'

describe "Vanagon::Common::Pathname" do
  describe "#has_overrides?" do
    it "is false for a pathname with just a path" do
      dir = Vanagon::Common::Pathname.new("/a/b/c")
      expect(dir.has_overrides?).to be(false)
    end

    it "is true if the pathname has more than a path set" do
      dir = Vanagon::Common::Pathname.new("/a/b/c", '0755')
      expect(dir.has_overrides?).to be(true)
    end
  end

  describe "equality" do
    it "is not equal if the paths differ" do
      dir1 = Vanagon::Common::Pathname.new("/a/b/c")
      dir2 = Vanagon::Common::Pathname.new("/a/b/c/d")
      expect(dir1).not_to eq(dir2)
    end

    it "is not equal if there are different attributes set" do
      dir1 = Vanagon::Common::Pathname.new("/a/b/c")
      dir2 = Vanagon::Common::Pathname.new("/a/b/c", '0123')
      expect(dir1).not_to eq(dir2)
    end

    it "is equal if there are the same attributes set to the same values" do
      dir1 = Vanagon::Common::Pathname.new("/a/b/c", '0123')
      dir2 = Vanagon::Common::Pathname.new("/a/b/c", '0123')
      expect(dir1).to eq(dir2)
    end

    it "is equal if the paths are the same and the only attribute set" do
      dir1 = Vanagon::Common::Pathname.new("/a/b/c")
      dir2 = Vanagon::Common::Pathname.new("/a/b/c")
      expect(dir1).to eq(dir2)
    end
  end
end
