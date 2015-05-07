require "../bson/lib_bson"

@[Link("mongoc-1.0")]
lib LibMongoC

  type MongoWriteConcern = Void*

  fun mongoc_write_concern_new = mongoc_write_concern_new() : MongoWriteConcern
  fun mongoc_write_concern_copy = mongoc_write_concern_copy(write_concern: MongoWriteConcern) : MongoWriteConcern
  fun mongoc_write_concern_destroy = mongoc_write_concern_destroy(write_concern: MongoWriteConcern)
  fun mongoc_write_concern_get_fsync = mongoc_write_concern_get_fsync(write_concern: MongoWriteConcern) : Bool
  fun mongoc_write_concern_set_fsync = mongoc_write_concern_set_fsync(write_concern: MongoWriteConcern, value : Bool)
  fun mongoc_write_concern_get_journal = mongoc_write_concern_get_journal(write_concern: MongoWriteConcern) : Bool
  fun mongoc_write_concern_set_journal = mongoc_write_concern_set_journal(write_concern: MongoWriteConcern, value: Bool)
  fun mongoc_write_concern_get_w = mongoc_write_concern_get_w(write_concern: MongoWriteConcern) : Int32
  fun mongoc_write_concern_set_w = mongoc_write_concern_set_w(write_concern: MongoWriteConcern, value: Int32)
  fun mongoc_write_concern_get_wtag = mongoc_write_concern_get_wtag(write_concern: MongoWriteConcern) : UInt8*
  fun mongoc_write_concern_set_wtag = mongoc_write_concern_set_wtag(write_concern: MongoWriteConcern, value: UInt8*)
  fun mongoc_write_concern_get_wtimeout = mongoc_write_concern_get_wtimeout(write_concern: MongoWriteConcern) : Int32
  fun mongoc_write_concern_set_wtimeout = mongoc_write_concern_set_wtimeout(write_concern: MongoWriteConcern, value: Int32)
  fun mongoc_write_concern_get_wmajority = mongoc_write_concern_get_wmajority(write_concern: MongoWriteConcern): Bool
  fun mongoc_write_concern_set_wmajority = mongoc_write_concern_set_wmajority(write_concern: MongoWriteConcern, value: Int32)

  BSON_HOST_NAME_MAX = 255 + 1
  BSON_HOST_NAME_AND_PORT_MAX = 255 + 7

  struct HostList
    next: HostList*
    host: UInt8[BSON_HOST_NAME_MAX]
    host_and_port: UInt8[BSON_HOST_NAME_AND_PORT_MAX]
    port: UInt16
    family: Int32
    padding: Void*[4]
  end

  alias MongoHostList = HostList*
  type MongoUri = Void*

  fun mongoc_uri_copy = mongoc_uri_copy(uri: MongoUri) : MongoUri
  fun mongoc_uri_destroy = mongoc_uri_destroy(uri: MongoUri)
  fun mongoc_uri_new = mongoc_uri_new(uri_string: UInt8*) : MongoUri
  fun mongoc_uri_new_for_host_port = mongoc_uri_new_for_host_port(host: UInt8*, port: UInt16) : MongoUri
  fun mongoc_uri_get_hosts = mongoc_uri_get_hosts(uri: MongoUri) : MongoHostList
  fun mongoc_uri_get_database = mongoc_uri_get_database(uri: MongoUri) : UInt8*
  fun mongoc_uri_get_options = mongoc_uri_get_options(uri: MongoUri) : LibBSON::BSON
  fun mongoc_uri_get_password = mongoc_uri_get_password(uri: MongoUri): UInt8*
  fun mongoc_uri_get_read_prefs = mongoc_uri_get_read_prefs(uri: MongoUri) : LibBSON::BSON
  fun mongoc_uri_get_replica_set = mongoc_uri_get_replica_set(uri: MongoUri) : UInt8*
  fun mongoc_uri_get_string = mongoc_uri_get_string(uri: MongoUri) : UInt8*
  fun mongoc_uri_get_username = mongoc_uri_get_username(uri: MongoUri) : UInt8*
  fun mongoc_uri_get_credentials = mongoc_uri_get_credentials(uri: MongoUri): LibBSON::BSON
  fun mongoc_uri_get_auth_source = mongoc_uri_get_auth_source(uri: MongoUri) : UInt8*
  fun mongoc_uri_get_auth_mechanism = mongoc_uri_get_auth_mechanism(uri: MongoUri) : UInt8*
  fun mongoc_uri_get_mechanism_properties = mongoc_uri_get_mechanism_properties(uri: MongoUri, properties: LibBSON::BSON) : Bool
  fun mongoc_uri_get_ssl = mongoc_uri_get_ssl(uri: MongoUri) : Bool
  fun mongoc_uri_unescape = mongoc_uri_unescape(escaped_string: UInt8*) : UInt8*
  fun mongoc_uri_get_write_concern = mongoc_uri_get_write_concern(uri: MongoUri) : MongoWriteConcern

  type MongoClient = Void*

  fun mongoc_client_new(uri_string: UInt8*) : MongoClient
end
