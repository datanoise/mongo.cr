class Mongo::WriteConcern
  def initialize(@handle : LibMongoC::WriteConcern)
    raise "invalid handle" unless @handle
  end

  def initialize
    initialize(LibMongoC.write_concern_new)
  end

  # Commenting prevents freeing bson pointers twice and crashing the program.
  # def finalize
  #   LibMongoC.write_concern_destroy(self)
  # end

  def clone
    WriteConcern.new(LibMongoC.write_concern_copy(self))
  end

  def fsync
    LibMongoC.write_concern_get_fsync(self)
  end

  def fsync=(value)
    LibMongoC.write_concern_set_fsync(self, value)
  end

  def journal
    LibMongoC.write_concern_get_journal(self)
  end

  def journal=(value)
    LibMongoC.write_concern_set_journal(self, value)
  end

  def w
    LibMongoC.write_concern_get_w(self)
  end

  def w=(value)
    LibMongoC.write_concern_set_w(self, value)
  end

  def wtag
    cstr = LibMongoC.write_concern_get_wtag(self)
    String.new(cstr) unless cstr.null?
  end

  def wtag=(value)
    LibMongoC.write_concern_set_wtag(self, value.to_unsafe)
  end

  def wtimeout
    LibMongoC.write_concern_get_wtimeout(self)
  end

  def wtimeout=(value)
    LibMongoC.write_concern_set_wtimeout(self, value)
  end

  def wmajority
    LibMongoC.write_concern_get_wmajority(self)
  end

  def wmajority=(value)
    LibMongoC.write_concern_set_wmajority(self, value)
  end

  def to_unsafe
    @handle
  end

  def to_s(io)
    io << "WriteConcern: "
    io << "fsync: #{fsync}, "
    io << "journal: #{journal}, "
    io << "w: #{w}, "
    io << "wtag: #{wtag}, "
    io << "wtimeout: #{wtimeout}, "
    io << "wmajority: #{wmajority}"
  end
end
