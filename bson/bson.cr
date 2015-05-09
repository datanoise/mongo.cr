require "./lib_bson"
require "../shims/time"

class BSON
  class BSONError < Exception
    getter domain
    getter code
    getter detail

    def initialize(bson_error)
      @domain = bson_error.domain
      @code = bson_error.code
      @detail = String.new bson_error.message.to_unsafe
      super("Domain: #{@domain}, code: #{@code}, #{@detail}")
    end
  end

  struct Binary
    enum SubType
      Binary
      Function
      UUID
      MD5
      User
    end

    property! subtype
    property! data

    def initialize(@subtype: SubType, @data: Slice(UInt8))
    end

    def to_raw_type
      case @subtype
      when SubType::Binary
        LibBSON::SubType::BSON_SUBTYPE_BINARY
      when SubType::Function
        LibBSON::SubType::BSON_SUBTYPE_FUNCTION
      when SubType::UUID
        LibBSON::SubType::BSON_SUBTYPE_UUID
      when SubType::MD5
        LibBSON::SubType::BSON_SUBTYPE_MD5
      when SubType::User
        LibBSON::SubType::BSON_SUBTYPE_USER
      else
        raise "unable to handle subtype #{@subtype}"
      end
    end
  end

  struct MinKey
    Instance = MinKey.allocate

    def self.new
      Instance
    end
  end

  struct MaxKey
    Instance = MaxKey.allocate

    def self.new
      Instance
    end
  end

  struct ObjectId
    include Comparable(ObjectId)

    def initialize(@handle: LibBSON::Oid*)
    end

    def initialize(str: String)
      handle = Pointer(LibBSON::Oid).malloc(1)
      LibBSON.bson_oid_init_from_string(handle, str.cstr)
      initialize(handle)
    end

    def initialize
      ctx = LibBSON.bson_context_get_default
      handle = Pointer(LibBSON::Oid).malloc(1)
      LibBSON.bson_oid_init(handle, ctx)
      initialize(handle)
    end

    def hash
      LibBSON.bson_oid_hash(@handle)
    end

    def to_s
      buf = StaticArray(UInt8, 25).new(0_u8)
      LibBSON.bson_oid_to_string(@handle, buf)
      String.new(buf.to_slice)
    end

    def ==(other: ObjectId)
      LibBSON.bson_oid_equal(@handle, other)
    end

    def ==(other)
      false
    end

    def <=>(other: ObjectId)
      LibBSON.bson_oid_compare(@handle, other)
    end

    def to_unsafe
      @handle
    end

    def time
      t = LibBSON.bson_oid_get_time_t(@handle)
      ts = LibC::TimeSpec.new
      ts.tv_sec = t
      Time.new(ts, Time::Kind::Utc)
    end
  end

  struct Symbol
    getter name

    def initialize(@name)
    end

    def bytesize
      @name.bytesize
    end

    def to_unsafe
      @name.to_unsafe
    end
  end

  struct Timestamp
    include Comparable(Timestamp)

    def initialize(@handle: LibBSON::Timestamp)
    end

    def initialize(timestamp, increment)
      handle = LibBSON::Timestamp.new
      handle.ts = timestamp.to_u32
      handle.incr = increment.to_u32
      initialize(handle)
    end

    def timestamp
      @handle.ts
    end

    def increment
      @handle.incr
    end

    def ==(other: Timestamp)
      timestamp == other.timestamp && increment == other.increment
    end

    def ==(other)
      false
    end

    def <=>(other: Timestamp)
      cmp = timestamp <=> other.timestamp
      if cmp == 0
        cmp = increment <=> other.increment
      end
      cmp
    end
  end

  struct Code
    getter code
    getter scope

    def initialize(@code, @scope = BSON.new)
    end

    def initialize(handle: LibBSON::Code)
      code = String.new(handle.code, handle.len.to_i32)
      initialize(code)
    end

    def initialize(handle: LibBSON::CodeWScope)
      code = String.new(handle.code, handle.code_len.to_i32)
      scope = BSON.from_data(Slice.new(handle.scope, handle.scope_len.to_i32))
      initialize(code, scope)
    end

    def ==(other: Code)
      code == other.code && scope == other.scope
    end

    def ==(other)
      false
    end
  end

  struct Value
    getter handle

    def initialize(src: LibBSON::BSONValue)
      LibBSON.bson_value_copy(src, out dst)
      @handle = dst
    end

    def finalize
      LibBSON.bson_value_destroy(@handle)
    end

    def value
      v = @handle.value
      case @handle.v_type
      when LibBSON::Type::BSON_TYPE_EOD
        nil
      when LibBSON::Type::BSON_TYPE_DOUBLE
        v.v_double
      when LibBSON::Type::BSON_TYPE_UTF8
        String.new(v.v_utf8.cstr, v.v_utf8.len.to_i32)
      when LibBSON::Type::BSON_TYPE_DOCUMENT
        BSON.from_data(Slice.new(v.v_doc.data, v.v_doc.len.to_i32))
      when LibBSON::Type::BSON_TYPE_ARRAY
        BSON.from_data(Slice.new(v.v_doc.data, v.v_doc.len.to_i32))
      when LibBSON::Type::BSON_TYPE_UNDEFINED
        raise "Deprecated BSON_TYPE_UNDEFINED must not be used"
      when LibBSON::Type::BSON_TYPE_OID
        oid = Pointer(LibBSON::Oid).malloc(1)
        LibBSON.bson_oid_copy(pointerof(v) as Pointer(LibBSON::Oid), oid)
        ObjectId.new(oid)
      when LibBSON::Type::BSON_TYPE_BOOL
        v.v_bool
      when LibBSON::Type::BSON_TYPE_DATE_TIME
        spec = LibC::TimeSpec.new
        spec.tv_sec = v.v_datetime / 1000
        Time.new(spec, Time::Kind::Utc)
      when LibBSON::Type::BSON_TYPE_NULL
        nil
      when LibBSON::Type::BSON_TYPE_REGEX
        opts = String.new(v.v_regex.options)
        modifiers = Regex::Options::None
        modifiers |= Regex::Options::IGNORE_CASE if opts.index('i')
        modifiers |= Regex::Options::MULTILINE if opts.index('m')
        modifiers |= Regex::Options::EXTENDED if opts.index('x')
        modifiers |= Regex::Options::UTF_8 if opts.index('u')
        Regex.new(String.new(v.v_regex.regex), modifiers)
      when LibBSON::Type::BSON_TYPE_DBPOINTER
        raise "Deprecated BSON_TYPE_DBPOINTER type must not be used"
      when LibBSON::Type::BSON_TYPE_CODE
        Code.new(v.v_code)
      when LibBSON::Type::BSON_TYPE_SYMBOL
        Symbol.new String.new(v.v_symbol.symbol, v.v_symbol.len)
      when LibBSON::Type::BSON_TYPE_CODEWSCOPE
        Code.new(v.v_codewscope)
      when LibBSON::Type::BSON_TYPE_INT32
        v.v_int32
      when LibBSON::Type::BSON_TYPE_TIMESTAMP
        Timestamp.new v.v_timestamp
      when LibBSON::Type::BSON_TYPE_INT64
        v.v_int64
      when LibBSON::Type::BSON_TYPE_MAXKEY
        MaxKey.new
      when LibBSON::Type::BSON_TYPE_MINKEY
        MinKey.new
      else
        raise "Invalid BSON Value type #{@handle.v_type}"
      end
    end
  end

  struct Iter
    include Iterator(Value)

    def initialize(@bson)
      @iter = Pointer(LibBSON::Iter).malloc(1)
      rewind
    end

    def next
      return stop unless LibBSON.bson_iter_next(@iter)
      Value.new(LibBSON.bson_iter_value(@iter))
    end

    def rewind
      LibBSON.bson_iter_init(@iter, @bson)
      self
    end
  end

  struct IterPair
    include Iterator(Value)

    def initialize(@bson)
      @iter = Pointer(LibBSON::Iter).malloc(1)
      rewind
    end

    def next
      return stop unless LibBSON.bson_iter_next(@iter)
      key = LibBSON.bson_iter_key(@iter)
      val = LibBSON.bson_iter_value(@iter)
      {String.new(key), Value.new(val)}
    end

    def rewind
      LibBSON.bson_iter_init(@iter, @bson)
      self
    end
  end

  struct IterKey
    include Iterator(String)

    def initialize(@bson)
      @iter = Pointer(LibBSON::Iter).malloc(1)
      rewind
    end

    def next
      return stop unless LibBSON.bson_iter_next(@iter)
      String.new LibBSON.bson_iter_key(@iter)
    end

    def rewind
      LibBSON.bson_iter_init(@iter, @bson)
      self
    end
  end

  struct ArrayAppender
    def initialize(@bson)
      @count = 0
    end

    def <<(value)
      @bson[@count.to_s] = value
      @count += 1
      self
    end
  end

  include Enumerable(Value)
  include Comparable(BSON)

  def initialize(@handle: LibBSON::BSON)
    @valid = true
  end

  def initialize
    initialize LibBSON.bson_new
  end

  def finalize
    LibBSON.bson_destroy(@handle) unless @valid
  end

  def self.from_json(json)
    handle = LibBSON.bson_new_from_json(json.cstr, json.bytesize, out error)
    if error
      raise BSONError.new(error)
    end
    new(handle)
  end

  def self.from_data(data: Slice(UInt8))
    handle = LibBSON.bson_new_from_data(data, data.length)
    new(handle)
  end

  def self.copy_from(data: LibBSON::BSON)
    handle = LibBSON.bson_copy(data)
    new(handle)
  end

  protected def invalidate
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

  def to_json
    cstr = LibBSON.bson_as_json(handle, out length)
    ret = String.new(cstr, length)
    LibBSON.bson_free(cstr as Void*)
    ret
  end

  def has_key?(key)
    LibBSON.bson_has_field(handle, key.cstr)
  end

  def ==(other: BSON)
    LibBSON.bson_equal(self, other)
  end

  def ==(other)
    false
  end

  def <=>(other: BSON)
    LibBSON.bson_compare(self, other)
  end

  def clear
    LibBSON.bson_reinit(self)
  end

  def concat(src: BSON)
    LibBSON.bson_concat(self, src)
    self
  end

  def clone
    BSON.new LibBSON.bson_copy(self)
  end

  def value(key)
    if LibBSON.bson_iter_init_find(out iter, handle, key.cstr)
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
    value(key) { raise IndexOutOfBounds.new }
  end

  def fetch(key: String)
    if LibBSON.bson_iter_init_find(out iter, handle, key.cstr)
      value = LibBSON.bson_iter_value(pointerof(iter))
      Value.new(value).value
    else
      yield key
    end
  end

  def []?(key: String)
    fetch(key) { nil }
  end

  def [](key: String)
    fetch(key) { raise IndexOutOfBounds.new }
  end

  def []=(key, value: Int32)
    LibBSON.bson_append_int32(handle, key.cstr, key.bytesize, value)
  end

  def []=(key, value: Int64)
    LibBSON.bson_append_int64(handle, key.cstr, key.bytesize, value)
  end

  def []=(key, value: Binary)
    LibBSON.bson_append_binary(handle, key.cstr, key.bytesize,
                               value.to_raw_type, value.data, value.data.length)
  end

  def []=(key, value: Bool)
    LibBSON.bson_append_bool(handle, key.cstr, key.bytesize, value)
  end

  def []=(key, value: Float64|Float32)
    LibBSON.bson_append_double(handle, key.cstr, key.bytesize, value.to_f64)
  end

  def []=(key, value: MinKey)
    LibBSON.bson_append_minkey(handle, key.cstr, key.bytesize)
  end

  def []=(key, value: MaxKey)
    LibBSON.bson_append_maxkey(handle, key.cstr, key.bytesize)
  end

  def []=(key, value: Nil)
    LibBSON.bson_append_null(handle, key.cstr, key.bytesize)
  end

  def []=(key, value: ObjectId)
    LibBSON.bson_append_oid(handle, key.cstr, key.bytesize, value)
  end

  def []=(key, value: String)
    LibBSON.bson_append_utf8(handle, key.cstr, key.bytesize, value, value.bytesize)
  end

  def []=(key, value: Symbol)
    LibBSON.bson_append_symbol(handle, key.cstr, key.bytesize, value, value.bytesize)
  end

  def []=(key, value: Time)
    LibBSON.bson_append_date_time(handle, key.cstr, key.bytesize, value.to_utc.to_i * 1000)
  end

  def []=(key, value: Timestamp)
    LibBSON.bson_append_timestamp(handle, key.cstr, key.bytesize, value.timestamp, value.increment)
  end

  def []=(key, value: Code)
    if value.scope.empty?
      LibBSON.bson_append_code(handle, key.cstr, key.bytesize, value.code.cstr)
    else
      LibBSON.bson_append_code_with_scope(handle, key.cstr, key.bytesize, value.code.cstr, value.scope)
    end
  end

  def []=(key, value: BSON)
    LibBSON.bson_append_document(handle, key.cstr, key.bytesize, value)
  end

  def []=(key, value: Regex)
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

    LibBSON.bson_append_regex(handle, key.cstr, key.bytesize, value.source.cstr, options.cstr)
  end

  def append_document(key)
    unless LibBSON.bson_append_document_begin(handle, key.cstr, key.bytesize, out child_handle)
      return false
    end
    child = BSON.new(pointerof(child_handle))
    begin
      yield child
    ensure
      LibBSON.bson_append_document_end(handle, child)
      child.invalidate
    end
  end

  def append_array(key)
    unless LibBSON.bson_append_array_begin(handle, key.cstr, key.bytesize, out child_handle)
      return false
    end
    child = BSON.new(pointerof(child_handle))
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

class Array(T)
  def to_bson(bson = BSON.new)
    each_with_index do |item, i|
      case item
      when Array
        bson.append_array(i.to_s) do |appender, child|
          item.to_bson(child)
        end
      when Hash
        bson.append_document(i.to_s) do |child|
          item.to_bson(child)
        end
      else
        bson[i.to_s] = item
      end
    end
    bson
  end
end

class Hash(K, V)
  def to_bson(bson = BSON.new)
    each do |k, v|
      case v
      when Array
        bson.append_array(k) do |appender, child|
          v.to_bson(child)
        end
      when Hash
        bson.append_document(k) do |child|
          v.to_bson(child)
        end
      else
        bson[k] = v
      end
    end
    bson
  end
end

struct Nil
  def to_bson
    self
  end
end
