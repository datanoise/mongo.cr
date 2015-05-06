class Mongo::WriteConcern
  def initialize(@handle: LibMongoC::MongoWriteConcern)
  end

  def initialize
    initialize(LibMongoC.mongoc_write_concern_new)
  end

  def finalize
    LibMongoC.mongoc_write_concern_destroy(self)
  end

  def clone
    WriteConcern.new(LibMongoC.mongoc_write_concern_copy(self))
  end

  def fsync
    LibMongoC.mongoc_write_concern_get_fsync(self)
  end

  def fsync=(value)
    LibMongoC.mongoc_write_concern_set_fsync(self, value)
  end

  def journal
    LibMongoC.mongoc_write_concern_get_journal(self)
  end

  def journal=(value)
    LibMongoC.mongoc_write_concern_set_journal(self, value)
  end

  def w
    LibMongoC.mongoc_write_concern_get_w(self)
  end

  def w=(value)
    LibMongoC.mongoc_write_concern_set_w(self, value)
  end

  def wtag
    cstr = LibMongoC.mongoc_write_concern_get_wtag(self)
    String.new(cstr)
  end

  def wtag=(value)
    LibMongoC.mongoc_write_concern_set_wtag(self, value.cstr)
  end

  def wtimeout
    LibMongoC.mongoc_write_concern_get_wtimeout(self)
  end

  def wtimeout=(value)
    LibMongoC.mongoc_write_concern_set_wtimeout(self, value)
  end

  def wmajority
    LibMongoC.mongoc_write_concern_get_wmajority(self)
  end

  def wmajority=(value)
    LibMongoC.mongoc_write_concern_set_wmajority(self, value)
  end

  def to_unsafe
    @handle
  end
end
