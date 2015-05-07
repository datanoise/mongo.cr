class Mongo::ReadPrefs
  def initialize(@handle = LibMongoC::ReadPrefs)
    raise "unable to initialize ReadPrefs" if @handle.nil?
  end

  def initialize(mode: LibMongoC::ReadMode)
    initialize LibMongoC.read_prefs_new(mode)
  end

  def finalize
    LibMongoC.read_prefs_destroy(self)
  end

  def clone
    ReadPrefs.new LibMongoC.read_prefs_copy(self)
  end

  def mode
    LibMongoC.read_prefs_get_mode(self)
  end

  def mode=(mode: LibMongoC::ReadMode)
    LibMongoC.read_prefs_set_mode(self, mode)
  end

  def tags
    bson = LibMongoC.read_prefs_get_tags(self)
    if bson.nil?
      BSON.new
    else
      BSON.new bson
    end
  end

  def tags=(tags)
    LibMongoC.read_prefs_set_tags(self, tags)
  end

  def add_tag(tag)
    LibMongoC.read_prefs_add_tag(self, tag)
  end

  def valid?
    LibMongoC.read_prefs_is_valid(self)
  end

  def to_unsafe
    @handle
  end
end
