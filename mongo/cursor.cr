require "../bson/bson"
require "./lib_mongo"
require "./host"

class Mongo::Cursor
  def initialize(@handle: LibMongoC::Cursor)
    @data = Pointer(LibBSON::BSON).malloc(1)
    @closed = false
  end

  include Enumerable(BSON)

  def finalize
    close
  end

  def close
    return if @closed
    @closed = true
    LibMongoC.cursor_destroy(self)
  end

  def clone
    handle = LibMongoC.cursor_clone(self)
    Cursor.new handle
  end

  def more
    LibMongoC.cursor_more(self)
  end

  def next
    if LibMongoC.cursor_next(self, @data)
      check_error
      @current = BSON.copy_from @data.value
    end
  end

  def each
    while v = self.next
      yield v
    end
  end

  private def check_error
    if LibMongoC.cursor_error(self, out error)
      raise BSON::BSONError.new(error)
    end
  end

  def host
    hosts = Host.hosts(LibMongoC.cursor_get_host(self))
    hosts.first
  end

  def alive
    LibMongoC.cursor_is_alive(self)
  end

  def current
    @current
  end

  def batch_size
    LibMongoC.cursor_get_batch_size(self)
  end

  def batch_size=(size)
    LibMongoC.cursor_set_batch_size(self, size.to_u32)
  end

  def hint
    LibMongoC.cursor_get_hint(self)
  end

  def id
    LibMongoC.cursor_get_id(self)
  end

  def to_unsafe
    @handle
  end
end
