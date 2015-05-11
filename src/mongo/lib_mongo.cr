@[Link("mongoc-1.0")]
lib LibMongoC
  enum LogLevel
    ERROR
    CRITICAL
    WARNING
    MESSAGE
    INFO
    DEBUG
    TRACE
  end

  fun log_set_handler = mongoc_log_set_handler((LogLevel, UInt8*, UInt8*, Void*) ->, Void*)

  alias BSON = LibBSON::BSON
  alias BSONError = LibBSON::BSONError

  type WriteConcern = Void*

  fun write_concern_new = mongoc_write_concern_new() : WriteConcern
  fun write_concern_copy = mongoc_write_concern_copy(write_concern: WriteConcern) : WriteConcern
  fun write_concern_destroy = mongoc_write_concern_destroy(write_concern: WriteConcern)
  fun write_concern_get_fsync = mongoc_write_concern_get_fsync(write_concern: WriteConcern) : Bool
  fun write_concern_set_fsync = mongoc_write_concern_set_fsync(write_concern: WriteConcern, value : Bool)
  fun write_concern_get_journal = mongoc_write_concern_get_journal(write_concern: WriteConcern) : Bool
  fun write_concern_set_journal = mongoc_write_concern_set_journal(write_concern: WriteConcern, value: Bool)
  fun write_concern_get_w = mongoc_write_concern_get_w(write_concern: WriteConcern) : Int32
  fun write_concern_set_w = mongoc_write_concern_set_w(write_concern: WriteConcern, value: Int32)
  fun write_concern_get_wtag = mongoc_write_concern_get_wtag(write_concern: WriteConcern) : UInt8*
  fun write_concern_set_wtag = mongoc_write_concern_set_wtag(write_concern: WriteConcern, value: UInt8*)
  fun write_concern_get_wtimeout = mongoc_write_concern_get_wtimeout(write_concern: WriteConcern) : Int32
  fun write_concern_set_wtimeout = mongoc_write_concern_set_wtimeout(write_concern: WriteConcern, value: Int32)
  fun write_concern_get_wmajority = mongoc_write_concern_get_wmajority(write_concern: WriteConcern): Bool
  fun write_concern_set_wmajority = mongoc_write_concern_set_wmajority(write_concern: WriteConcern, value: Int32)

  BSON_HOST_NAME_MAX = 255 + 1
  BSON_HOST_NAME_AND_PORT_MAX = 255 + 7

  struct HostListStruct
    next: HostListStruct*
    host: UInt8[BSON_HOST_NAME_MAX]
    host_and_port: UInt8[BSON_HOST_NAME_AND_PORT_MAX]
    port: UInt16
    family: Int32
    padding: Void*[4]
  end

  alias HostList = HostListStruct*
  type Uri = Void*

  fun uri_copy = mongoc_uri_copy(uri: Uri) : Uri
  fun uri_destroy = mongoc_uri_destroy(uri: Uri)
  fun uri_new = mongoc_uri_new(uri_string: UInt8*) : Uri
  fun uri_new_for_host_port = mongoc_uri_new_for_host_port(host: UInt8*, port: UInt16) : Uri
  fun uri_get_hosts = mongoc_uri_get_hosts(uri: Uri) : HostList
  fun uri_get_database = mongoc_uri_get_database(uri: Uri) : UInt8*
  fun uri_get_options = mongoc_uri_get_options(uri: Uri) : BSON
  fun uri_get_password = mongoc_uri_get_password(uri: Uri): UInt8*
  fun uri_get_read_prefs = mongoc_uri_get_read_prefs(uri: Uri) : BSON
  fun uri_get_replica_set = mongoc_uri_get_replica_set(uri: Uri) : UInt8*
  fun uri_get_string = mongoc_uri_get_string(uri: Uri) : UInt8*
  fun uri_get_username = mongoc_uri_get_username(uri: Uri) : UInt8*
  fun uri_get_credentials = mongoc_uri_get_credentials(uri: Uri): BSON
  fun uri_get_auth_source = mongoc_uri_get_auth_source(uri: Uri) : UInt8*
  fun uri_get_auth_mechanism = mongoc_uri_get_auth_mechanism(uri: Uri) : UInt8*
  fun uri_get_mechanism_properties = mongoc_uri_get_mechanism_properties(uri: Uri, properties: BSON) : Bool
  fun uri_get_ssl = mongoc_uri_get_ssl(uri: Uri) : Bool
  fun uri_unescape = mongoc_uri_unescape(escaped_string: UInt8*) : UInt8*
  fun uri_get_write_concern = mongoc_uri_get_write_concern(uri: Uri) : WriteConcern

  type Cursor = Void*

  fun cursor_clone = mongoc_cursor_clone(cursor: Cursor) : Cursor
  fun cursor_destroy = mongoc_cursor_destroy(cursor: Cursor)
  fun cursor_more = mongoc_cursor_more(cursor: Cursor) : Bool
  fun cursor_next = mongoc_cursor_next(cursor: Cursor, bson: BSON*) : Bool
  fun cursor_error = mongoc_cursor_error(cursor: Cursor, error: BSONError*) : Bool
  fun cursor_get_host = mongoc_cursor_get_host(cursor: Cursor, host: HostList)
  fun cursor_is_alive = mongoc_cursor_is_alive(cursor: Cursor) : Bool
  fun cursor_current = mongoc_cursor_current(cursor: Cursor) : BSON
  fun cursor_set_batch_size = mongoc_cursor_set_batch_size(cursor: Cursor, batch_size: UInt32)
  fun cursor_get_batch_size = mongoc_cursor_get_batch_size(cursor: Cursor) : UInt32
  fun cursor_get_hint = mongoc_cursor_get_hint(cursor: Cursor) : UInt32
  fun cursor_get_id = mongoc_cursor_get_id(cursor: Cursor) : Int64

  type ReadPrefs = Void*

  enum ReadMode
    PRIMARY             = (1 << 0)
    SECONDARY           = (1 << 1)
    PRIMARY_PREFERRED   = (1 << 2) | PRIMARY
    SECONDARY_PREFERRED = (1 << 2) | SECONDARY
    NEAREST             = (1 << 3) | SECONDARY
  end

  fun read_prefs_new = mongoc_read_prefs_new(mode: ReadMode) : ReadPrefs
  fun read_prefs_copy = mongoc_read_prefs_copy(prefs: ReadPrefs) : ReadPrefs
  fun read_prefs_destroy = mongoc_read_prefs_destroy(prefs: ReadPrefs)
  fun read_prefs_get_mode = mongoc_read_prefs_get_mode(prefs: ReadPrefs) : ReadMode
  fun read_prefs_set_mode = mongoc_read_prefs_set_mode(prefs: ReadPrefs, mode: ReadMode)
  fun read_prefs_get_tags = mongoc_read_prefs_get_tags(prefs: ReadPrefs) : BSON
  fun read_prefs_set_tags = mongoc_read_prefs_set_tags(prefs: ReadPrefs, tags: BSON)
  fun read_prefs_add_tag = mongoc_read_prefs_add_tag(prefs: ReadPrefs, tag: BSON)
  fun read_prefs_is_valid = mongoc_read_prefs_is_valid(prefs: ReadPrefs) : Bool

  enum QueryFlags
    NONE              = 0
    TAILABLE_CURSOR   = 1 << 1
    SLAVE_OK          = 1 << 2
    OPLOG_REPLAY      = 1 << 3
    NO_CURSOR_TIMEOUT = 1 << 4
    AWAIT_DATA        = 1 << 5
    EXHAUST           = 1 << 6
    PARTIAL           = 1 << 7
  end

  enum InsertFlags
    NONE              = 0
    CONTINUE_ON_ERROR = 1 << 0
  end

  enum UpdateFlags
    NONE         = 0
    UPSERT       = 1 << 0
    MULTI_UPDATE = 1 << 1
  end

  enum RemoveFlags
    NONE          = 0
    SINGLE_REMOVE = 1 << 0
  end

  struct IndexOpt
    is_initialized: Bool
    background: Bool
    unique: Bool
    name: UInt8*
    drop_dups: Bool
    sparse: Bool
    expire_after_seconds: Int32
    v: Int32
    weights: BSON
    default_language: UInt8*
    language_override: UInt8*
    geo_options: Void* # FIXME
    storage_options: Void* #FIXME
    padding: Void*[6]
  end

  fun index_opt_get_default = mongoc_index_opt_get_default(): IndexOpt*
  fun index_opt_init = mongoc_index_opt_init(opt: IndexOpt*)

  type BulkOperation = Void*

  fun bulk_operation_destroy = mongoc_bulk_operation_destroy(bulk: BulkOperation)
  fun bulk_operation_execute = mongoc_bulk_operation_execute(bulk: BulkOperation, reply: BSON,
                                                             error: BSONError*) : UInt32
  fun bulk_operation_remove = mongoc_bulk_operation_remove(bulk: BulkOperation, selector: BSON)
  fun bulk_operation_insert = mongoc_bulk_operation_insert(bulk: BulkOperation, document: BSON)
  fun bulk_operation_remove_one = mongoc_bulk_operation_remove_one(bulk: BulkOperation, selector: BSON)
  fun bulk_operation_replace_one = mongoc_bulk_operation_replace_one(bulk: BulkOperation, selector: BSON,
                                                                     document: BSON, upsert: Bool)
  fun bulk_operation_update = mongoc_bulk_operation_update(bulk: BulkOperation, selector: BSON,
                                                           document: BSON, upsert: Bool)
  fun bulk_operation_update_one = mongoc_bulk_operation_update_one(bulk: BulkOperation, selector: BSON,
                                                                   document: BSON, upsert: Bool)

  type Collection = Void*

  fun collection_aggregate = mongoc_collection_aggregate(collection: Collection, flags: QueryFlags,
                                                         pipeline: BSON, options: BSON,
                                                         prefs: ReadPrefs) : Cursor
  fun collection_destroy = mongoc_collection_destroy(collection: Collection)
  fun collection_command = mongoc_collection_command(collection: Collection, flags: QueryFlags,
                                                     skip: UInt32, limit: UInt32, batch_size: UInt32,
                                                     command: BSON, fields: BSON,
                                                     prefs: ReadPrefs) : Cursor
  fun collection_command_simple = mongoc_collection_command_simple(collection: Collection, command: BSON,
                                                                   prefs: ReadPrefs, reply: BSON,
                                                                   error: BSONError*) : Bool
  fun collection_count = mongoc_collection_count(collection: Collection, flags: QueryFlags, query: BSON,
                                                 skip: Int64, limit: Int64, prefs: ReadPrefs,
                                                 error: BSONError*) : Int64
  fun collection_count_with_opts = mongoc_collection_count_with_opts(collection: Collection, flags: QueryFlags,
                                                                     query: BSON, skip: Int64, limit: Int64,
                                                                     opts: BSON, prefs: ReadPrefs,
                                                                     error: BSONError*) : Int64
  fun collection_drop = mongoc_collection_drop(collection: Collection, error: BSONError*) : Bool
  fun collection_drop_index = mongoc_collection_drop_index(collection: Collection, index_name: UInt8*,
                                                           error: BSONError*) : Bool
  fun collection_create_index = mongoc_collection_create_index(collection: Collection, keys: BSON,
                                                               opt: IndexOpt*, error: BSONError*) : Bool
  fun collection_find_indexes = mongoc_collection_find_indexes(collection: Collection, error: BSONError*) : Cursor
  fun collection_find = mongoc_collection_find(collection: Collection, flags: QueryFlags, skip: UInt32, limit: UInt32,
                                               batch_size: UInt32, query: BSON, fields: BSON,
                                               prefs: ReadPrefs) : Cursor
  fun collection_insert = mongoc_collection_insert(collection: Collection, flags: InsertFlags, document: BSON,
                                                   write_concern: WriteConcern, error: BSONError*) : Bool
  fun collection_insert_bulk = mongoc_collection_insert_bulk(collection: Collection, flags: InsertFlags,
                                                             documents: BSON*, n_documents: UInt32,
                                                             write_concern: WriteConcern, error: BSONError*) : Bool
  fun collection_update = mongoc_collection_update(collection: Collection, flags: UpdateFlags, selector: BSON,
                                                   update: BSON, write_concern: WriteConcern,
                                                   error: BSONError*) : Bool
  fun collection_save = mongoc_collection_save(collection: Collection, document: BSON,
                                               write_concern: WriteConcern, error: BSONError*) : Bool
  fun collection_remove = mongoc_collection_remove(collection: Collection, flags: RemoveFlags,
                                                   selector: BSON, write_concern: WriteConcern,
                                                   error: BSONError*) : Bool
  fun collection_rename = mongoc_collection_rename(collection: Collection, new_db: UInt8*, new_name: UInt8*,
                                                   drop_target_before_rename: Bool, error: BSONError*) : Bool
  fun collection_find_and_modify = mongoc_collection_find_and_modify(collection: Collection, query: BSON,
                                                                     sort: BSON, update: BSON,
                                                                     fields: BSON, remove: Bool, upsert: Bool,
                                                                     new: Bool, reply: BSON,
                                                                     error: BSONError*) : Bool
  fun collection_stats = mongoc_collection_stats(collection: Collection, options: BSON, reply: BSON,
                                                 error: BSONError*) : Bool
  fun collection_create_bulk_operation = mongoc_collection_create_bulk_operation(collection: Collection, ordered: Bool,
                                                                                 write_concern: WriteConcern) : BulkOperation
  fun collection_get_read_prefs = mongoc_collection_get_read_prefs(collection: Collection) : ReadPrefs
  fun collection_set_read_prefs = mongoc_collection_set_read_prefs(collection: Collection, prefs: ReadPrefs)
  fun collection_get_write_concern = mongoc_collection_get_write_concern(collection: Collection) : WriteConcern
  fun collection_set_write_concern = mongoc_collection_set_write_concern(collection: Collection, write_concern: WriteConcern)
  fun collection_get_name = mongoc_collection_get_name(collection: Collection) : UInt8*
  fun collection_get_last_error = mongoc_collection_get_last_error(collection: Collection) : BSON
  fun collection_keys_to_index_string = mongoc_collection_keys_to_index_string(keys: BSON) : UInt8*
  fun collection_validate = mongoc_collection_validate(collection: Collection, options: BSON, reply: BSON,
                                                       error: BSONError*) : Bool

  type Database = Void*

  fun database_get_name = mongoc_database_get_name(db: Database) : UInt8*
  fun database_remove_user = mongoc_database_remove_user(db: Database, username: UInt8*, error: BSONError*) : Bool
  fun database_remove_all_users = mongoc_database_remove_all_users(db: Database, error: BSONError*) : Bool
  fun database_add_user = mongoc_database_add_user(db: Database, username: UInt8*, password: UInt8*,
                                                   roles: BSON, custom_data: BSON, error: BSONError*) : Bool
  fun database_destroy = mongoc_database_destroy(db: Database)
  fun database_command = mongoc_database_command(db: Database, flags: QueryFlags, skip: UInt32, limit: UInt32,
                                                 batch_size: UInt32, command: BSON, fields: BSON, prefs: ReadPrefs) : Cursor
  fun database_command_simple = mongoc_database_command_simple(db: Database, command: BSON, prefs: ReadPrefs,
                                                               reply: BSON, error: BSONError*) : Bool
  fun database_drop = mongoc_database_drop(db: Database, error: BSONError*) : Bool
  fun database_has_collection = mongoc_database_has_collection(db: Database, name: UInt8*, error: BSONError*) : Bool
  fun database_create_collection = mongoc_database_create_collection(db: Database, name: UInt8*, options: BSON,
                                                                     error: BSONError*) : Collection
  fun database_get_read_prefs = mongoc_database_get_read_prefs(db: Database) : ReadPrefs
  fun database_set_read_prefs = mongoc_database_set_read_prefs(db: Database, prefs: ReadPrefs)
  fun database_get_write_concern = mongoc_database_get_write_concern(db: Database) : WriteConcern
  fun database_set_write_concern = mongoc_database_set_write_concern(db: Database, write_concern: WriteConcern)
  fun database_find_collections = mongoc_database_find_collections(db: Database, filter: BSON, error: BSONError*) : Cursor
  fun database_get_collection_names = mongoc_database_get_collection_names(db: Database, error: BSONError*): UInt8**
  fun database_get_collection = mongoc_database_get_collection(db: Database, name: UInt8*): Collection

  type Client = Void*

  fun client_new = mongoc_client_new(uri_string: UInt8*) : Client
  fun client_new_from_uri = mongoc_client_new_from_uri(uri: Uri) : Client
  fun client_get_uri = mongoc_client_get_uri(client: Client) : Uri
  fun client_command = mongoc_client_command(client: Client, db_name: UInt8*, flags: QueryFlags,
                                             skip: UInt32, limit: UInt32, batch_size: UInt32,
                                             query: BSON, fields: BSON, prefs: ReadPrefs) : Cursor
  fun client_kill_cursor = mongoc_client_kill_cursor(client: Client, cursor_id: Int64)
  fun client_command_simple = mongoc_client_command_simple(client: Client, db_name: UInt8*, command: BSON,
                                                           prefs: ReadPrefs, reply: BSON, error: BSONError*) : Bool
  fun client_destroy = mongoc_client_destroy(client: Client)
  fun client_get_database = mongoc_client_get_database(client: Client, name: UInt8*) : Database
  fun client_get_collection = mongoc_client_get_collection(client: Client, db: UInt8*, collection: UInt8*) : Collection
  fun client_get_database_names = mongoc_client_get_database_names(client: Client, error: BSONError*) : UInt8**
  fun client_find_databases = mongoc_client_find_databases(client: Client, error: BSONError*) : Cursor
  fun client_get_server_status = mongoc_client_get_server_status(client: Client, prefs: ReadPrefs,
                                                                 reply: BSON, error: BSONError*) : Bool
  fun client_get_max_message_size = mongoc_client_get_max_message_size(client: Client) : Int32
  fun client_get_max_bson_size = mongoc_client_get_max_bson_size(client: Client) : Int32
  fun client_get_write_concern = mongoc_client_get_write_concern(client: Client) : WriteConcern
  fun client_set_write_concern = mongoc_client_set_write_concern(client: Client, write_concern: WriteConcern)
  fun client_get_read_prefs = mongoc_client_get_read_prefs(client: Client) : ReadPrefs
  fun client_set_read_prefs = mongoc_client_set_read_prefs(client: Client, prefs: ReadPrefs)
  # fun client_set_ssl_opts = mongoc_client_set_ssl_opts(client: Client, opts: SSLOpt)
end
