require "./client"

class Mongo::Database
  @client : Mongo::Client
  @handle : LibMongoC::Database

  getter client

  def initialize(@client, @handle = LibMongoC::Database)
    raise "invalid handle" unless @handle
  end

  def finalize
    LibMongoC.database_destroy(@handle)
  end

  # Fetches the name of the database.
  def name
    String.new LibMongoC.database_get_name(self)
  end

  # This method removes the user named `username` from database.
  def remove_user(username)
    unless LibMongoC.database_remove_user(self, username, out error)
      raise BSON::BSONError.new(pointerof(error))
    end
  end

  # This method will remove all users configured to access database.
  def remove_all_users
    unless LibMongoC.database_remove_all_users(self, out error)
      raise BSON::BSONError.new(pointerof(error))
    end
  end

  # This method shall create a new user with access to database.
  def add_user(username, password, roles = nil, custom_data = nil)
    unless LibMongoC.database_add_user(self, username, password, roles.to_bson, custom_data.to_bson, out error)
      raise BSON::BSONError.new(pointerof(error))
    end
  end

  # Fetches all users that allowed access to this database.
  def users
    cmd = BSON.new
    cmd["usersInfo"] = 1
    res = command_simple(cmd)
    if res && (users = res["users"]) && users.is_a?(BSON)
      users
    end
  end

  # This method shall execute a command on a database.
  def command(command, fields = BSON.new, flags = LibMongoC::QueryFlags::NONE,
              skip = 0, limit = 0, batch_size = 0, prefs = nil)
    Cursor.new LibMongoC.database_command(self, flags, skip.to_u32, limit.to_u32, batch_size.to_u32,
                                          command.to_bson, fields.to_bson, prefs)
  end

  # This method shall execute a command on a database.
  # The result is passed to the specified block.
  def command(command, fields = BSON.new, flags = LibMongoC::QueryFlags::NONE,
              skip = 0, limit = 0, batch_size = 0, prefs = nil)
    command(command, fields, flags, skip, limit, batch_size, prefs).each do |doc|
      yield doc
    end
  end

  # This is a simplified interface to command that returns the first result document.
  def command_simple(command, prefs = nil)
    unless LibMongoC.database_command_simple(self, command.to_bson, prefs, out reply, out error)
      raise BSON::BSONError.new(pointerof(error))
    end
    repl = BSON.copy_from pointerof(reply)
    LibBSON.bson_destroy(pointerof(reply))
    repl
  end

  # This method attempts to drop a database on the MongoDB server.
  def drop
    unless LibMongoC.database_drop(self, out error)
      raise BSON::BSONError.new(pointerof(error))
    end
  end

  # This method checks to see if a collection exists on the MongoDB server
  # within database.
  def has_collection?(name)
    unless LibMongoC.database_has_collection(self, name, out error)
      unless error.code == 0
        raise BSON::BSONError.new(pointerof(error))
      end
      return false
    end
    true
  end

  # This method create a new collection named `name`.
  def create_collection(name, options = nil)
   col = LibMongoC.database_create_collection(self, name, options, out error)
   unless col
      raise BSON::BSONError.new(pointerof(error))
   end
   Collection.new self, col
  end

  def gridfs(prefix = "fs")
    @client.gridfs(name, prefix)
  end

  # Fetches the default read preferences to use with database.
  def read_prefs
    ReadPrefs.new LibMongoC.database_get_read_prefs(self)
  end

  # This method sets the default read preferences to use on operations performed
  # with database. Collections created with `collection(name)` after this call
  # will inherit these read preferences.
  def read_prefs=(value)
    LibMongoC.database_set_read_prefs(self, value)
  end

  # This method retrieves the default WriteConcern to use with database as
  # configured by the client.
  def write_concern
    WriteConcern.new LibMongoC.database_get_write_concern(self)
  end

  # This method sets the default write concern to use on operations performed
  # with database. Collections created with `collection(name)` after this call
  # will inherit this write concern.
  def write_concern=(value)
    LibMongoC.database_set_write_concern(self, value)
  end

  # Fetches a cursor containing documents, each corresponding to a collection
  # on this database.
  def find_collections(filter = BSON.new)
    cur = LibMongoC.database_find_collections(self, filter.to_bson, out error)
    unless cur
      raise BSON::BSONError.new(pointerof(error))
    end
    Cursor.new cur
  end

  # Fetches a cursor containing documents, each corresponding to a collection
  # on this database.
  # Results are passed to the specified block.
  def find_collections(filter = BSON.new)
    find_collections(filter).each do |doc|
      yield doc
    end
  end

  # Returns an `Array` of names of all of the collections in database
  def collection_names
    names = LibMongoC.database_get_collection_names(self, out error)
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

  # Allocates a new `Collection` structure for the collection named `name` in database.
  def collection(name)
    Collection.new self, LibMongoC.database_get_collection(self, name)
  end

  # See `collection(name)`
  def [](name)
    collection(name)
  end

  def to_unsafe
    @handle
  end
end
