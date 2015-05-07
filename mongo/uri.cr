require "../bson/bson"
require "./lib_mongo"
require "./write_concern"

class Mongo::Host
  getter host
  getter port
  getter family

  def initialize(@host, @port, @family)
  end
end

class Mongo::Uri
  def initialize(@handle: LibMongoC::MongoUri)
    raise "unable to parse Uri" unless @handle
    @hosts = [] of Host
  end

  def initialize(uri)
    initialize LibMongoC.mongoc_uri_new(uri.cstr)
  end

  def initialize(host, port)
    initialize LibMongoC.mongoc_uri_new_for_host_port(host.cstr, port.to_u16)
  end

  def finalize
    LibMongoC.mongoc_uri_destroy(self)
  end

  def hosts
    if @hosts.empty?
      cur = LibMongoC.mongoc_uri_get_hosts(self)
      loop do
        break if cur.nil?
        @hosts << Host.new(String.new(cur.value.host.buffer), cur.value.port, cur.value.family)
        cur = cur.value.next
        break if cur.nil?
      end
    end
    @hosts
  end

  def database
    cstr = LibMongoC.mongoc_uri_get_database(@handle)
    String.new cstr unless cstr.nil?
  end

  def options
    bson = LibMongoC.mongoc_uri_get_options(self)
    if bson.nil?
      BSON.new
    else
      BSON.new bson
    end
  end

  def password
    cstr = LibMongoC.mongoc_uri_get_password(self)
    String.new cstr unless cstr.nil?
  end

  def read_prefs
    bson = LibMongoC.mongoc_uri_get_read_prefs(self)
    if bson.nil?
      BSON.new
    else
      BSON.new bson
    end
  end

  def replica_set
    cstr = LibMongoC.mongoc_uri_get_replica_set(self)
    String.new cstr unless cstr.nil?
  end

  def string
    cstr = LibMongoC.mongoc_uri_get_string(self)
    String.new cstr unless cstr.nil?
  end

  def username
    cstr = LibMongoC.mongoc_uri_get_username(self)
    String.new cstr unless cstr.nil?
  end

  def credentials
    cstr = LibMongoC.mongoc_uri_get_credentials(self)
    BSON.new cstr unless cstr.nil?
  end

  def auth_source
    cstr = LibMongoC.mongoc_uri_get_auth_source(self)
    String.new cstr unless cstr.nil?
  end

  def auth_mechanism
    cstr = LibMongoC.mongoc_uri_get_auth_mechanism(self)
    String.new cstr unless cstr.nil?
  end

  def mechanism_properties
    BSON.new.tap do |bson|
      LibMongoC.mongoc_uri_get_mechanism_properties(self, bson)
    end
  end

  def ssl
    LibMongoC.mongoc_uri_get_ssl(self)
  end

  def self.unescape(uri)
    cstr = LibMongoC.mongoc_uri_unescape(uri)
    return "" unless cstr.nil?
    String.new(cstr).tap do
      LibBSON.bson_destroy(cstr)
    end
  end

  def write_concern
    handle = LibMongoC.mongoc_uri_get_write_concern(self)
    if handle.nil?
      WriteConcern.new
    else
      WriteConcern.new handle
    end
  end

  def to_unsafe
    @handle
  end
end
