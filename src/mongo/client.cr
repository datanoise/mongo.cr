require "./uri"
require "./stream/initiator"
require "./lib_mongo"

# Client class provides access to a MongoDB node, replica-set, or
# sharded-cluster. It maintains management of underlying sockets and routing to
# individual nodes based on ReadPrefs and WriteConcern classes.
#
class Mongo::Client
  @handle : LibMongoC::Client
  property pooled : Bool = false

  def initialize(@handle : LibMongoC::Client,@pooled : Bool = false)
    raise "invalid handle" unless @handle
  end

  # Creates a new Client using uri expressed as a String or Uri class instance.
  def initialize(uri : String | Uri = "mongodb://localhost")
    handle =
      if uri.is_a?(String)
        LibMongoC.client_new(uri)
      else
        LibMongoC.client_new_from_uri(uri)
      end
    initialize handle
  end

  # Use this method to set up the crystal implementation of underlying stream API.
  # This is useful to make mongo client's IO operations to play nicely with Fiber API.
  def setup_stream
    LibMongoC.client_set_stream_initiator(self, -> Stream::Initiator.initiator, nil)
  end

  # Returns a Uri instance used to create Client.
  def uri
    Uri.new LibMongoC.client_get_uri(self)
  end

  # This method executes a command on the server using the database and command
  # specification provided.
  def command(db_name, query, fields = BSON.new, flags = LibMongoC::QueryFlags::NONE,
              skip = 0, limit = 0, batch_size = 0, prefs = nil)
    Cursor.new LibMongoC.client_command(self, db_name, flags, skip.to_u32, limit.to_u32, batch_size.to_u32,
                                        query, fields, prefs)
  end

  # This method executes a command on the server using the database and command
  # specification provided.  Result is passed to the provided block.
  def command(db_name, query, fields = BSON.new, flags = LibMongoC::QueryFlags::NONE,
              skip = 0, limit = 0, batch_size = 0, prefs = nil)
    command(db_name, query, fields, flags, skip, limit, batch_size, prefs).each do |doc|
      yield doc
    end
  end

  # This is a simplified interface to command execution. It returns the first
  # document from the result cursor.
  def command_simple(db_name, command, prefs = nil)
    unless LibMongoC.client_command_simple(self, db_name, command, prefs, out reply, out error)
      raise BSON::BSONError.new(pointerof(error))
    end
    repl = BSON.copy_from pointerof(reply)
    LibBSON.bson_destroy(pointerof(reply))
    repl
  end

  def kill_cursor(cursor_id)
    LibMongoC.client_kill_cursor(self, cursor_id.to_i64)
  end

  # Get a newly allocated Database for the database named name.
  def database(name)
    Database.new self, LibMongoC.client_get_database(self, name)
  end

  # Alias for `database(name)` method
  def [](name)
    database(name)
  end

  # Get a newly allocated Collection for the collection named `collection_name`
  # in the database named `db_name`.
  def collection(db_name, collection_name)
    #database(db_name).collection(collection_name)
    Collection.new LibMongoC.client_get_collection(self, db_name,collection_name)
  end

  # This method queries the MongoDB server for a list of known databases.
  def database_names
    names = LibMongoC.client_get_database_names(self, out error)
    unless names
      raise BSON::BSONError.new(pointerof(error))
    end
    ret = [] of String
    count = 0
    loop do
      cur = names[count]
      break if cur.null?
      ret << String.new(cur)
      count += 1
    end
    LibBSON.bson_strfreev(names)
    ret
  end

  # This method return `Cursor` of all known database names.
  def find_databases
    cur = LibMongoC.client_find_databases(self, out error)
    unless cur
      raise BSON::BSONError.new(pointerof(error))
    end
    Cursor.new cur
  end

  # This method return `Cursor` of all known database names.
  # The result is passed as an argument to the specified block.
  def find_databases
    find_databases.each do |doc|
      yield doc
    end
  end

  # Queries the server for the current server status.
  def server_status(prefs = nil)
    unless LibMongoC.client_get_server_status(self, prefs, out reply, out error)
      raise BSON::BSONError.new(pointerof(error))
    end
    repl = BSON.copy_from pointerof(reply)
    LibBSON.bson_destroy(pointerof(reply))
    repl
  end

  # Create GridFS instance.
  #
  # @param db: the name of the database which the gridfs instance should exist in.
  #
  # @param prefix:  corresponds to the gridfs collection namespacing; its
  # default is "fs", thus the default GridFS collection names are "fs.files"
  # and "fs.chunks".
  def gridfs(db, prefix = "fs")
    handle = LibMongoC.client_get_gridfs(self, db, prefix, out error)
    unless handle
      raise BSON::BSONError.new(pointerof(error))
    end
    GridFS::FS.new database(db), handle
  end

  # This method returns the maximum message size allowed by the cluster. Until
  # a connection has been made, this will be the default of 40Mb.
  def max_message_size
    LibMongoC.client_get_max_message_size(self)
  end

  # The method returns the maximum bson document size allowed by the cluster.
  # Until a connection has been made, this will be the default of 16Mb.
  def max_bson_size
    LibMongoC.client_get_max_bson_size(self)
  end

  # Retrieve the default write concern configured for the client instance.
  def write_concern
    WriteConcern.new LibMongoC.client_get_write_concern(self)
  end

  # Sets the default write concern for the `Client`. This only affects future
  # operations, collections, and databases inheriting from client.
  def write_concern=(write_concern)
    LibMongoC.client_set_write_concern(self, write_concern)
  end

  # Retrieves the default read preferences configured for the client instance.
  def read_prefs
    ReadPrefs.new LibMongoC.client_get_read_prefs(self)
  end

  # Sets the default read preferences to use with future operations upon `Client`.
  def read_prefs=(value : ReadPrefs)
    LibMongoC.client_set_read_prefs(self, value)
  end

  # Commenting prevents freeing bson pointers twice and crashing the program.
  # def finalize
  #   if !@pooled
  #       LibMongoC.client_destroy(self)
  #   end
  # end

  def to_unsafe
    @handle
  end
end

class Mongo::ClientPool
  @handle : LibMongoC::ClientPool
  def initialize(@handle : LibMongoC::ClientPool)
    raise "invalid handle" unless @handle
    @valid = true
  end
  # Creates a new Client using uri expressed as a String or Uri class instance.
  def initialize(uri : String | Uri = "mongodb://localhost")
    handle =
      if uri.is_a?(String)
        LibMongoC.client_pool_new(Mongo::Uri.new(uri))
      else
        LibMongoC.client_pool_new(uri)
      end
    initialize handle
  end
  def pop
    Client.new(LibMongoC.client_pool_pop(self),true)
  end
  def push(client : Client)
    LibMongoC.client_pool_push(self,client)
  end
  def try_pop
    handle = LibMongoC.client_pool_try_pop(self)
    if handle
        Client.new(handle,true)
    else
        nil
    end
  end
  def max_size=(size : UInt32)
    LibMongoC.client_pool_max_size(self,size)
  end
  def min_size=(size : UInt32)
    LibMongoC.client_pool_min_size(self,size)
  end
  def invalidate
    @valid = false
    LibMongoC.client_pool_destroy(@handle)
  end
  def finalize
    LibMongoC.client_pool_destroy(self) if @valid
  end
  def to_unsafe
    @handle
  end
end
