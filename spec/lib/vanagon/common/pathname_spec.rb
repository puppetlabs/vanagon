require 'vanagon/common/pathname'

describe "Vanagon::Common::Pathname" do
  describe "#has_overrides?" do
    it "is false for a pathname with just a path" do
      dir = Vanagon::Common::Pathname.new("/a/b/c")
      expect(dir.has_overrides?).to be(false)
    end

    it "is true if the pathname has more than a path set" do
      dir = Vanagon::Common::Pathname.new("/a/b/c", mode: '0755')
      expect(dir.has_overrides?).to be(true)
    end
  end

  describe "#file" do
    it 'creates a new Pathname instance, marked as a file' do
      dir = Vanagon::Common::Pathname.file("/a/b/c/")
      expect(dir.class).to eq(Vanagon::Common::Pathname)
      expect(dir.configfile?).to eq(false)
    end
  end

  describe "#configfile" do
    it 'creates a new Pathname instance, marked as a configuration file' do
      dir = Vanagon::Common::Pathname.configfile("/a/b/c/")
      expect(dir.class).to eq(Vanagon::Common::Pathname)
      expect(dir.configfile?).to eq(true)
    end
  end

  describe "#initialize" do
    it 'strips trailing slashes off of the path to normalize it' do
      dir = Vanagon::Common::Pathname.new("/a/b/c/")
      expect(dir.path).to eq("/a/b/c")
    end

    it 'removes extra / from the pathname to normalize it' do
      dir = Vanagon::Common::Pathname.new("/a//b///c///")
      expect(dir.path).to eq("/a/b/c")
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
      dir2 = Vanagon::Common::Pathname.new("/a/b/c", mode: '0123')
      expect(dir1).not_to eq(dir2)
    end

    it "is equal if there are the same attributes set to the same values" do
      dir1 = Vanagon::Common::Pathname.new("/a/b/c", mode: '0123')
      dir2 = Vanagon::Common::Pathname.new("/a/b/c", mode: '0123')
      expect(dir1).to eq(dir2)
    end

    it "is equal if the paths are the same and the only attribute set" do
      dir1 = Vanagon::Common::Pathname.new("/a/b/c")
      dir2 = Vanagon::Common::Pathname.new("/a/b/c")
      expect(dir1).to eq(dir2)
    end
  end

  describe "#hash" do
    it "has the same hash is the attributes are the same" do
      dir1 = Vanagon::Common::Pathname.new("/a/b/c", mode: '0123')
      dir2 = Vanagon::Common::Pathname.new("/a/b/c", mode: '0123')
      expect(dir1.hash).to eq(dir2.hash)
    end

    it "has different hashes if any attribute is different" do
      dir1 = Vanagon::Common::Pathname.new("/a/b/c", mode: '0123', owner: 'alice')
      dir2 = Vanagon::Common::Pathname.new("/a/b/c", mode: '0123', owner: 'bob')
      expect(dir1.hash).to_not eq(dir2.hash)
    end
  end

  describe "uniqueness of pathnames" do
    it "should only add 1 Pathname object with the same attributes to a set" do
      set = Set.new
      dir1 = Vanagon::Common::Pathname.new("/a/b/c", mode: '0123')
      dir2 = Vanagon::Common::Pathname.new("/a/b/c", mode: '0123')
      dir3 = Vanagon::Common::Pathname.new("/a/b/c", mode: '0123', owner: 'alice')
      set << dir1 << dir2 << dir3
      expect(set.size).to eq(2)
    end

    it "should reduce an array to unique elements successfully" do
      dir1 = Vanagon::Common::Pathname.new("/a/b/c", mode: '0123')
      dir2 = Vanagon::Common::Pathname.new("/a/b/c", mode: '0123')
      dir3 = Vanagon::Common::Pathname.new("/a/b/c", mode: '0123', owner: 'alice')
      arr = [ dir1, dir2, dir3 ]
      expect(arr.size).to eq(3)
      expect(arr.uniq.size).to eq(2)
    end
  end
end
