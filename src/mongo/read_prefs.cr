class Mongo::ReadPrefs
  def initialize(@handle : LibMongoC::ReadPrefs)
    raise "invalid handle" unless @handle
  end

  def initialize(mode : LibMongoC::ReadMode = LibMongoC::ReadMode::PRIMARY)
    initialize LibMongoC.read_prefs_new(mode)
  end

  # Commenting prevents freeing bson pointers twice and crashing the program.
  # def finalize
  #   LibMongoC.read_prefs_destroy(self)
  # end

  def clone
    ReadPrefs.new LibMongoC.read_prefs_copy(self)
  end

  def mode
    LibMongoC.read_prefs_get_mode(self)
  end

  def mode=(mode : LibMongoC::ReadMode)
    LibMongoC.read_prefs_set_mode(self, mode)
  end

  def tags
    bson = LibMongoC.read_prefs_get_tags(self)
    if bson.null?
      BSON.new
    else
      BSON.new bson
    end
  end

  def tags=(tags)
    LibMongoC.read_prefs_set_tags(self, tags.to_bson)
  end

  def add_tag(tag)
    LibMongoC.read_prefs_add_tag(self, tag.to_bson)
  end

  def valid?
    LibMongoC.read_prefs_is_valid(self)
  end

  def to_unsafe
    @handle
  end

  def to_s(io)
    io << "ReadPrefs: "
    io << "mode: #{mode}, "
    io << "tags: #{tags}, "
    io << "valid?: #{valid?}"
  end
end
