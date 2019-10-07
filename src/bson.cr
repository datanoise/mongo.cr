require "./bson/lib_bson"
require "./bson/core_ext/*"
require "./bson/*"

class BSON
  @handle : LibBSON::BSON
  @valid : Bool = false
  @owned : Bool = true
  include Enumerable(Value)
  include Comparable(BSON)

  def initialize(@handle : LibBSON::BSON, @owned : Bool = true)
    raise "invalid handle" unless @handle
    @valid = true
  end

  def initialize
    initialize LibBSON.bson_new
  end

  def finalize
    LibBSON.bson_destroy(@handle) if @valid && @owned
  end

  def self.from_json(json)
    handle = LibBSON.bson_new_from_json(json, json.bytesize, out error)
    if handle.null? && error
      raise BSONError.new(pointerof(error))
    end
    new(handle,true)
  end

  def self.not_initialized
    ptr = Pointer(LibBSON::BSONHandle).malloc(1)
    new(ptr,false)
  end

  def self.from_data(data : Slice(UInt8))
    handle = LibBSON.bson_new_from_data(data, data.size)
    new(handle)
  end

  def self.copy_from(data : LibBSON::BSON)
    handle = LibBSON.bson_copy(data)
    new(handle)
  end

  def invalidate
    LibBSON.bson_destroy(@handle) if @owned && @valid
    @owned = false
    @valid = false
  end

  protected def handle
    raise "Using invalid BSON handle" unless @valid
    @handle
  end

  def count
    LibBSON.bson_count_keys(handle)
  end

  def empty?
    count == 0
  end

  def to_json(json : JSON::Builder)
    l = to_json
    json.raw l
  end

  def to_json
    cstr = LibBSON.bson_as_json(handle, out length)
    ret = String.new(cstr, length)
    LibBSON.bson_free(cstr.as(Void*))
    ret
  end

  def has_key?(key)
    LibBSON.bson_has_field(handle, key)
  end

  def ==(other : BSON)
    LibBSON.bson_equal(self, other)
  end

  def ==(other)
    false
  end

  def <=>(other : BSON)
    LibBSON.bson_compare(self, other)
  end

  def clear
    LibBSON.bson_reinit(self)
  end

  def concat(src : BSON)
    LibBSON.bson_concat(self, src)
    self
  end

  def clone
    BSON.new LibBSON.bson_copy(self)
  end

  def value(key)
    if LibBSON.bson_iter_init_find(out iter, handle, key)
      value = LibBSON.bson_iter_value(pointerof(iter))
      Value.new(value)
    else
      yield key
    end
  end

  def value?(key)
    value(key) { nil }
  end

  def value(key)
    value(key) { raise IndexError.new }
  end

  def fetch(key : String)
    if LibBSON.bson_iter_init_find(out iter, handle, key)
      value = LibBSON.bson_iter_value(pointerof(iter))
      Value.new(value).value
    else
      yield key
    end
  end

  def []?(key : String)
    fetch(key) { nil }
  end

  def [](key : String)
    fetch(key) { raise IndexError.new }
  end

  def []=(key, value : Int32)
    LibBSON.bson_append_int32(handle, key, key.bytesize, value)
  end

  def []=(key, value : Int64)
    LibBSON.bson_append_int64(handle, key, key.bytesize, value)
  end

  def []=(key, value : Binary)
    LibBSON.bson_append_binary(handle, key, key.bytesize,
                               value.to_raw_type, value.data, value.data.size)
  end

  def []=(key, value : Bool)
    LibBSON.bson_append_bool(handle, key, key.bytesize, value)
  end

  def []=(key, value : Float64|Float32)
    LibBSON.bson_append_double(handle, key, key.bytesize, value.to_f64)
  end

  def []=(key, value : MinKey)
    LibBSON.bson_append_minkey(handle, key, key.bytesize)
  end

  def []=(key, value : MaxKey)
    LibBSON.bson_append_maxkey(handle, key, key.bytesize)
  end

  def []=(key, value : Nil)
    LibBSON.bson_append_null(handle, key, key.bytesize)
  end

  def []=(key, value : ObjectId)
    LibBSON.bson_append_oid(handle, key, key.bytesize, value)
  end

  def []=(key, value : String)
    LibBSON.bson_append_utf8(handle, key, key.bytesize, value, value.bytesize)
  end

  def []=(key, value : Symbol)
    LibBSON.bson_append_symbol(handle, key, key.bytesize, value, value.bytesize)
  end

  def []=(key, value : Time)
    LibBSON.bson_append_date_time(handle, key, key.bytesize, value.to_utc.to_unix * 1000)
  end

  def []=(key, value : Timestamp)
    LibBSON.bson_append_timestamp(handle, key, key.bytesize, value.timestamp, value.increment)
  end

  def []=(key, value : Code)
    if value.scope.empty?
      LibBSON.bson_append_code(handle, key, key.bytesize, value.code)
    else
      LibBSON.bson_append_code_with_scope(handle, key, key.bytesize, value.code, value.scope)
    end
  end

  def []=(key, value : BSON)
    LibBSON.bson_append_document(handle, key, key.bytesize, value)
  end

  def []=(key, value : Regex)
    modifiers = value.options
    options =
      if modifiers
        String.build do |buf|
          buf << "i" if modifiers.includes? Regex::Options::IGNORE_CASE
          buf << "m" if modifiers.includes? Regex::Options::MULTILINE
          buf << "x" if modifiers.includes? Regex::Options::EXTENDED
          buf << "u" if modifiers.includes? Regex::Options::UTF_8
        end
      else
        ""
      end
    LibBSON.bson_append_regex(handle, key, key.bytesize, value.source, options)
  end

  def append_document(key)
    child_handle = LibBSON.bson_new()
    unless LibBSON.bson_append_document_begin(handle, key, key.bytesize, child_handle)
      return false
    end
    child = BSON.new child_handle
    begin
      yield child
    ensure
      LibBSON.bson_append_document_end(handle, child)
      child.invalidate
    end
  end

  def append_array(key)
    child_handle = LibBSON.bson_new()
    unless LibBSON.bson_append_array_begin(handle, key, key.bytesize, child_handle)
      return false
    end
    child = BSON.new(child_handle)
    begin
      yield ArrayAppender.new(child), child
    ensure
      LibBSON.bson_append_array_end(handle, child)
      child.invalidate
    end
  end

  def data
    data = LibBSON.bson_get_data(handle)
    Slice.new(data, handle.value.len.to_i32)
  end

  def each
    LibBSON.bson_iter_init(out iter, handle)
    while LibBSON.bson_iter_next(pointerof(iter))
      value = LibBSON.bson_iter_value(pointerof(iter))
      yield Value.new(value)
    end
  end

  def each
    Iter.new(self)
  end

  def each_pair
    LibBSON.bson_iter_init(out iter, handle)
    while LibBSON.bson_iter_next(pointerof(iter))
      key = LibBSON.bson_iter_key(pointerof(iter))
      value = LibBSON.bson_iter_value(pointerof(iter))
      yield String.new(key), Value.new(value)
    end
  end

  def each_pair
    IterPair.new(self)
  end

  def each_key
    LibBSON.bson_iter_init(out iter, handle)
    while LibBSON.bson_iter_next(pointerof(iter))
      key = LibBSON.bson_iter_key(pointerof(iter))
      yield String.new(key)
    end
  end

  def each_key
    IterKey.new(self)
  end

  def to_unsafe
    handle
  end

  def to_s(io)
    io << to_json
  end

  def inspect(io)
    to_s(io)
  end

  def to_bson
    self
  end

  alias Field = Nil         |
               Int32        |
               Int64        |
               Binary       |
               Bool         |
               Float32      |
               Float64      |
               MinKey       |
               MaxKey       |
               ObjectId     |
               String       |
               Symbol       |
               Time         |
               Timestamp    |
               Code         |
               BSON         |
               Regex        |
               Array(Field) |
               Hash(String, Field)

  def decode
    if array?
      each_with_object([] of Field) {|v, res| res << decode_value(v.value)}
    else
      each_pair.each_with_object({} of String => Field) {|pair, h| h[pair[0]] = decode_value(pair[1].value)}
    end
  end

  private def decode_value(v)
    case v
    when BSON
      v.decode
    else
      v
    end
  end

  def array?
    count = -1
    each_key.all? do |k|
      count += 1
      k == count.to_s
    end
  end
end
