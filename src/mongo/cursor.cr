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

  private def check_closed
    raise "cursor is closed" if @closed
  end

  def clone
    check_closed
    handle = LibMongoC.cursor_clone(self)
    Cursor.new handle
  end

  def more
    check_closed
    LibMongoC.cursor_more(self)
  end

  def next
    check_closed
    if LibMongoC.cursor_next(self, @data)
      check_error
      @current = BSON.copy_from @data.value
    end
  end

  def each
    check_closed
    while v = self.next
      yield v
    end
  end

  private def check_error
    if LibMongoC.cursor_error(self, out error)
      raise BSON::BSONError.new(pointerof(error))
    end
  end

  def host
    check_closed
    LibMongoC.cursor_get_host(self, out hosts)
    Host.hosts(pointerof(hosts)).first
  end

  def alive?
    return false if @closed
    LibMongoC.cursor_is_alive(self)
  end

  def current
    check_closed
    @current
  end

  def batch_size
    check_closed
    LibMongoC.cursor_get_batch_size(self)
  end

  def batch_size=(size)
    check_closed
    LibMongoC.cursor_set_batch_size(self, size.to_u32)
  end

  def hint
    check_closed
    LibMongoC.cursor_get_hint(self)
  end

  def id
    check_closed
    LibMongoC.cursor_get_id(self)
  end

  def to_unsafe
    check_closed
    @handle
  end
end
