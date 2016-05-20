require "./lib_mongo"
require "./host"
require "./write_concern"

class Mongo::Uri
  def initialize(@handle : LibMongoC::Uri)
    raise "invalid handle" unless @handle
    @hosts = [] of Host
  end

  def initialize(uri)
    initialize LibMongoC.uri_new(uri.to_unsafe)
  end

  def initialize(host, port)
    initialize LibMongoC.uri_new_for_host_port(host.to_unsafe, port.to_u16)
  end

  def finalize
    LibMongoC.uri_destroy(self)
  end

  def clone
    Uri.new LibMongoC.uri_copy(self)
  end

  def hosts
    if @hosts.empty?
      @hosts = Host.hosts(LibMongoC.uri_get_hosts(self))
    end
    @hosts
  end

  def database
    cstr = LibMongoC.uri_get_database(@handle)
    String.new cstr unless cstr.null?
  end

  def options
    bson = LibMongoC.uri_get_options(self)
    if bson.null?
      BSON.new
    else
      BSON.new bson
    end
  end

  def password
    cstr = LibMongoC.uri_get_password(self)
    String.new cstr unless cstr.null?
  end

  def read_prefs
    bson = LibMongoC.uri_get_read_prefs(self)
    if bson.null?
      BSON.new
    else
      BSON.new bson
    end
  end

  def replica_set
    cstr = LibMongoC.uri_get_replica_set(self)
    String.new cstr unless cstr.null?
  end

  def string
    cstr = LibMongoC.uri_get_string(self)
    String.new cstr unless cstr.null?
  end

  def username
    cstr = LibMongoC.uri_get_username(self)
    String.new cstr unless cstr.null?
  end

  def credentials
    cstr = LibMongoC.uri_get_credentials(self)
    BSON.new cstr unless cstr.null?
  end

  def auth_source
    cstr = LibMongoC.uri_get_auth_source(self)
    String.new cstr unless cstr.null?
  end

  def auth_mechanism
    cstr = LibMongoC.uri_get_auth_mechanism(self)
    String.new cstr unless cstr.null?
  end

  def mechanism_properties
    BSON.new.tap do |bson|
      LibMongoC.uri_get_mechanism_properties(self, bson)
    end
  end

  def ssl
    LibMongoC.uri_get_ssl(self)
  end

  def self.unescape(uri)
    cstr = LibMongoC.uri_unescape(uri)
    return "" unless cstr.null?
    String.new(cstr).tap do
      LibBSON.bson_destroy(cstr)
    end
  end

  def write_concern
    handle = LibMongoC.uri_get_write_concern(self)
    if handle.null?
      WriteConcern.new
    else
      WriteConcern.new handle
    end
  end

  def to_unsafe
    @handle
  end
end
