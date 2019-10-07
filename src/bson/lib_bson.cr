@[Link("bson-1.0")]
lib LibBSON
  alias BSONContext = Void*

  struct BSONHandle
    flags: UInt32
    len: UInt32
    padding: UInt8[120]
  end

  alias BSON = BSONHandle*

  struct BSONError
    domain: UInt32
    code: UInt32
    message: UInt8[504]
  end

  enum SubType
    BSON_SUBTYPE_BINARY = 0x00
    BSON_SUBTYPE_FUNCTION = 0x01
    BSON_SUBTYPE_BINARY_DEPRECATED = 0x02
    BSON_SUBTYPE_UUID_DEPRECATED = 0x03
    BSON_SUBTYPE_UUID = 0x04
    BSON_SUBTYPE_MD5 = 0x05
    BSON_SUBTYPE_USER = 0x80
  end

  enum Type
    BSON_TYPE_EOD = 0x00
    BSON_TYPE_DOUBLE = 0x01
    BSON_TYPE_UTF8 = 0x02
    BSON_TYPE_DOCUMENT = 0x03
    BSON_TYPE_ARRAY = 0x04
    BSON_TYPE_BINARY = 0x05
    BSON_TYPE_UNDEFINED = 0x06
    BSON_TYPE_OID = 0x07
    BSON_TYPE_BOOL = 0x08
    BSON_TYPE_DATE_TIME = 0x09
    BSON_TYPE_NULL = 0x0A
    BSON_TYPE_REGEX = 0x0B
    BSON_TYPE_DBPOINTER = 0x0C
    BSON_TYPE_CODE = 0x0D
    BSON_TYPE_SYMBOL = 0x0E
    BSON_TYPE_CODEWSCOPE = 0x0F
    BSON_TYPE_INT32 = 0x10
    BSON_TYPE_TIMESTAMP = 0x11
    BSON_TYPE_INT64 = 0x12
    BSON_TYPE_MAXKEY = 0x7F
    BSON_TYPE_MINKEY = 0xFF
  end

  enum ErrorDomain
     MONGOC_ERROR_CLIENT = 1,
     MONGOC_ERROR_STREAM,
     MONGOC_ERROR_PROTOCOL,
     MONGOC_ERROR_CURSOR,
     MONGOC_ERROR_QUERY,
     MONGOC_ERROR_INSERT,
     MONGOC_ERROR_SASL,
     MONGOC_ERROR_BSON,
     MONGOC_ERROR_MATCHER,
     MONGOC_ERROR_NAMESPACE,
     MONGOC_ERROR_COMMAND,
     MONGOC_ERROR_COLLECTION,
     MONGOC_ERROR_GRIDFS,
     MONGOC_ERROR_SCRAM,
     MONGOC_ERROR_SERVER_SELECTION,
     MONGOC_ERROR_WRITE_CONCERN,
     MONGOC_ERROR_SERVER,
     MONGOC_ERROR_TRANSACTION,
  end
	
  enum ErrorCode
     MONGOC_ERROR_STREAM_INVALID_TYPE = 1,
     MONGOC_ERROR_STREAM_INVALID_STATE,
     MONGOC_ERROR_STREAM_NAME_RESOLUTION,
     MONGOC_ERROR_STREAM_SOCKET,
     MONGOC_ERROR_STREAM_CONNECT,
     MONGOC_ERROR_STREAM_NOT_ESTABLISHED,
     MONGOC_ERROR_CLIENT_NOT_READY,
     MONGOC_ERROR_CLIENT_TOO_BIG,
     MONGOC_ERROR_CLIENT_TOO_SMALL,
     MONGOC_ERROR_CLIENT_GETNONCE,
     MONGOC_ERROR_CLIENT_AUTHENTICATE,
     MONGOC_ERROR_CLIENT_NO_ACCEPTABLE_PEER,
     MONGOC_ERROR_CLIENT_IN_EXHAUST,
     MONGOC_ERROR_PROTOCOL_INVALID_REPLY,
     MONGOC_ERROR_PROTOCOL_BAD_WIRE_VERSION,
     MONGOC_ERROR_CURSOR_INVALID_CURSOR,
     MONGOC_ERROR_QUERY_FAILURE,
     MONGOC_ERROR_BSON_INVALID,
     MONGOC_ERROR_MATCHER_INVALID,
     MONGOC_ERROR_NAMESPACE_INVALID,
     MONGOC_ERROR_NAMESPACE_INVALID_FILTER_TYPE,
     MONGOC_ERROR_COMMAND_INVALID_ARG,
     MONGOC_ERROR_COLLECTION_INSERT_FAILED,
     MONGOC_ERROR_COLLECTION_UPDATE_FAILED,
     MONGOC_ERROR_COLLECTION_DELETE_FAILED,
     MONGOC_ERROR_COLLECTION_DOES_NOT_EXIST = 26,
     MONGOC_ERROR_GRIDFS_INVALID_FILENAME,
     MONGOC_ERROR_SCRAM_NOT_DONE,
     MONGOC_ERROR_SCRAM_PROTOCOL_ERROR,
     MONGOC_ERROR_QUERY_COMMAND_NOT_FOUND = 59,
     MONGOC_ERROR_QUERY_NOT_TAILABLE = 13051,
     MONGOC_ERROR_SERVER_SELECTION_BAD_WIRE_VERSION,
     MONGOC_ERROR_SERVER_SELECTION_FAILURE,
     MONGOC_ERROR_SERVER_SELECTION_INVALID_ID,
     MONGOC_ERROR_GRIDFS_CHUNK_MISSING,
     MONGOC_ERROR_GRIDFS_PROTOCOL_ERROR,
     MONGOC_ERROR_PROTOCOL_ERROR = 17,
     MONGOC_ERROR_WRITE_CONCERN_ERROR = 64,
     MONGOC_ERROR_DUPLICATE_KEY = 11000,
     MONGOC_ERROR_MAX_TIME_MS_EXPIRED = 50,
     MONGOC_ERROR_CHANGE_STREAM_NO_RESUME_TOKEN,
     MONGOC_ERROR_CLIENT_SESSION_FAILURE,
     MONGOC_ERROR_TRANSACTION_INVALID_STATE,
     MONGOC_ERROR_GRIDFS_CORRUPT,
     MONGOC_ERROR_GRIDFS_BUCKET_FILE_NOT_FOUND,
     MONGOC_ERROR_GRIDFS_BUCKET_STREAM
  end


  struct Oid
    bytes: UInt8[12]
  end

  struct Timestamp
    ts: UInt32
    incr: UInt32
  end

  struct Utf8
    cstr: UInt8*
    len: UInt32
  end

  struct Doc
    data: UInt8*
    len: UInt32
  end

  struct Binary
    data: UInt8*
    len: UInt32
    sub_type: SubType
  end

  struct Regex
    regex: UInt8*
    options: UInt8*
  end

  struct DBPointer
    collection: UInt8*
    len: UInt32
    oid: Oid
  end

  struct Code
    code: UInt8*
    len: UInt32
  end

  struct CodeWScope
    code: UInt8*
    scope: UInt8*
    code_len: UInt32
    scope_len: UInt32
  end

  struct Symbol
    symbol: UInt8*
    len: UInt32
  end

  union ValueUnion
    v_oid: Oid
    v_int64: Int64
    v_int32: Int32
    v_int8: Int8
    v_double: Float64
    v_bool: Bool
    v_datetime: Int64
    v_timestamp: Timestamp
    v_utf8: Utf8
    v_doc: Doc
    v_binary: Binary
    v_regex: Regex
    v_dbpointer: DBPointer
    v_code: Code
    v_codewscope: CodeWScope
    v_symbol: Symbol
  end

  struct Value
    v_type: Type
    padding: Int32
    value: ValueUnion
  end

  alias BSONValue = Value*

  struct Iter
    raw: UInt8*
    len: UInt32
    off: UInt32
    type: UInt32
    key: UInt32
    d1: UInt32
    d2: UInt32
    d3: UInt32
    d4: UInt32
    next_off: UInt32
    err_off: UInt32
    value: Value
  end

  alias BSONIter = Iter*

  fun bson_free = bson_free(Void*)
  fun bson_strfreev = bson_strfreev(UInt8**)

  fun bson_context_get_default = bson_context_get_default() : BSONContext

  fun bson_new = bson_new() : BSON
  fun bson_init = bson_init(bson: BSON)
  fun bson_new_from_json = bson_new_from_json(data: UInt8*, len: Int32, error: BSONError*) : BSON
  fun bson_init_from_json = bson_init_from_json(bson: BSON, data: UInt8*, len: Int32, error: BSONError*) : Bool
  fun bson_new_from_data = bson_new_from_data(data: UInt8*, length: Int32) : BSON
  fun bson_destroy = bson_destroy(bson: BSON)
  fun bson_get_data = bson_get_data(bson: BSON) : UInt8*
  fun bson_count_keys = bson_count_keys(bson: BSON) : UInt32
  fun bson_as_json = bson_as_canonical_extended_json(bson: BSON, length: Int32*) : UInt8*
  fun bson_has_field = bson_has_field(bson: BSON, key: UInt8*) : Bool
  fun bson_equal = bson_equal(bson: BSON, other: BSON) : Bool
  fun bson_compare = bson_compare(bson: BSON, other: BSON) : Int32
  fun bson_reinit = bson_reinit(bson: BSON)
  fun bson_copy = bson_copy(bson: BSON) : BSON
  fun bson_concat = bson_concat(bson: BSON, src: BSON) : Bool

  fun bson_append_binary = bson_append_binary(bson: BSON, key: UInt8*, key_length: Int32, subtype: SubType, binary: UInt8*, length: Int32) : Bool
  fun bson_append_int32 = bson_append_int32(bson: BSON, key: UInt8*, key_length: Int32, value: Int32) : Bool
  fun bson_append_int64 = bson_append_int64(bson: BSON, key: UInt8*, key_length: Int32, value: Int64) : Bool
  fun bson_append_bool = bson_append_bool(bson: BSON, key: UInt8*, key_length: Int32, value: Bool) : Bool
  fun bson_append_double = bson_append_double(bson: BSON, key: UInt8*, key_length: Int32, value: Float64) : Bool
  fun bson_append_minkey = bson_append_minkey(bson: BSON, key: UInt8*, key_length: Int32) : Bool
  fun bson_append_maxkey = bson_append_maxkey(bson: BSON, key: UInt8*, key_length: Int32) : Bool
  fun bson_append_null = bson_append_null(bson: BSON, key: UInt8*, key_length: Int32) : Bool
  fun bson_append_oid = bson_append_oid(bson: BSON, key: UInt8*, key_length: Int32, oid: Oid*) : Bool
  fun bson_append_utf8 = bson_append_utf8(bson: BSON, key: UInt8*, key_length: Int32, value: UInt8*, length: Int32) : Bool
  fun bson_append_document_begin = bson_append_document_begin(bson: BSON, key: UInt8*, key_length: Int32, child: BSON) : Bool
  fun bson_append_document_end = bson_append_document_end(bson: BSON, child: BSON) : Bool
  fun bson_append_document = bson_append_document(bson: BSON, key: UInt8*, key_length: Int32, value: BSON) : Bool
  fun bson_append_array_begin = bson_append_array_begin(bson: BSON, key: UInt8*, key_length: Int32, child: BSON) : Bool
  fun bson_append_array_end = bson_append_array_end(bson: BSON, child: BSON) : Bool
  fun bson_append_symbol = bson_append_symbol(bson: BSON, key: UInt8*, key_length: Int32, value: UInt8*, length: Int32) : Bool
  fun bson_append_date_time = bson_append_date_time(bson: BSON, key: UInt8*, key_length: Int32, value: Int64) : Bool
  fun bson_append_timestamp = bson_append_timestamp(bson: BSON, key: UInt8*, key_length: Int32, ts: UInt32, incr: UInt32) : Bool
  fun bson_append_regex = bson_append_regex(bson: BSON, key: UInt8*, key_length: Int32, regex: UInt8*, options: UInt8*) : Bool
  fun bson_append_code = bson_append_code(bson: BSON, key: UInt8*, key_length: Int32, code: UInt8*) : Bool
  fun bson_append_code_with_scope = bson_append_code_with_scope(bson: BSON, key: UInt8*, key_length: Int32, code: UInt8*, scope: BSON) : Bool

  fun bson_iter_init = bson_iter_init(iter: BSONIter, bson: BSON) : Bool
  fun bson_iter_init_find = bson_iter_init_find(iter: BSONIter, bson: BSON, key: UInt8*) : Bool
  fun bson_iter_next = bson_iter_next(iter: BSONIter) : Bool
  fun bson_iter_key = bson_iter_key(iter: BSONIter) : UInt8*
  fun bson_iter_value = bson_iter_value(iter: BSONIter) : BSONValue

  fun bson_value_copy = bson_value_copy(src: BSONValue, dst: BSONValue)
  fun bson_value_destroy = bson_value_destroy(v: BSONValue)

  fun bson_oid_init = bson_oid_init(oid: Oid*, context: BSONContext)
  fun bson_oid_init_from_string = bson_oid_init_from_string(oid: Oid*, str: UInt8*)
  fun bson_oid_hash = bson_oid_hash(oid: Oid*) : UInt32
  fun bson_oid_get_time_t = bson_oid_get_time_t(oid: Oid*) : LibC::TimeT
  fun bson_oid_equal = bson_oid_equal(oid1: Oid*, oid2: Oid*) : Bool
  fun bson_oid_compare = bson_oid_compare(oid1: Oid*, oid2: Oid*) : Int32
  fun bson_oid_to_string = bson_oid_to_string(oid: Oid*, str: UInt8[25])
  fun bson_oid_copy = bson_oid_copy(src: Oid*, dst: Oid*)
end
