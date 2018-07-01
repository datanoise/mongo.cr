require "./lib_bson"

class BSON
  class Value
    @handle : LibBSON::Value

    getter handle

    def initialize(src : LibBSON::BSONValue)
      LibBSON.bson_value_copy(src, out dst)
      @handle = dst
    end

    def finalize
      LibBSON.bson_value_destroy(pointerof(@handle))
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
        LibBSON.bson_oid_copy(pointerof(v).as(Pointer(LibBSON::Oid)), oid)
        ObjectId.new(oid)
      when LibBSON::Type::BSON_TYPE_BOOL
        v.v_bool
      when LibBSON::Type::BSON_TYPE_DATE_TIME
        spec = LibC::Timespec.new
        spec.tv_sec = v.v_datetime / 1000
        Time.new(spec, Time::Location::UTC)
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
end
