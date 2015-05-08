class Mongo::Database
  def initialize(@handle = LibMongoC::Database)
    unless @handle
      raise "Unable to initialize Database"
    end
  end

  def finalize
    LibMongoC.database_destroy(self)
  end

  def name
    String.new LibMongoC.database_get_name(self)
  end

  def remove_user(username)
    unless LibMongoC.database_remove_user(self, username, out error)
      raise BSON::BSONError.new(error)
    end
  end

  def remove_all_users
    unless LibMongoC.database_remove_all_users(self, out error)
      raise BSON::BSONError.new(error)
    end
  end

  def add_user(username, password, roles = nil, custom_data = nil)
    unless LibMongoC.database_add_user(self, username, password, roles.to_bson, custom_data.to_bson, out error)
      raise BSON::BSONError.new(error)
    end
  end

  def users
    cmd = BSON.new
    cmd["usersInfo"] = 1
    res = command(cmd).next
    if res && (users = res["users"]) && users.is_a?(BSON)
      users
    end
  end

  def command(command, fields = BSON.new, flags = LibMongoC::QueryFlags::QUERY_NONE,
              skip = 0, limit = 0, batch_size = 0, prefs = nil)
    Cursor.new LibMongoC.database_command(self, flags, skip.to_u32, limit.to_u32, batch_size.to_u32,
                                          command.to_bson, fields.to_bson, prefs)
  end

  def command_simple(command, prefs = nil)
    unless LibMongoC.database_command_simple(self, command.to_bson, prefs, out reply, out error)
      raise BSON::BSONError.new(error)
    end
    BSON.copy_from pointerof(reply)
  end

  def drop
    unless LibMongoC.database_drop(self, out error)
      raise BSON::BSONError.new(error)
    end
  end

  def has_collection?(name)
    unless LibMongoC.database_has_collection(self, name, out error)
      unless error.code == 0
        raise BSON::BSONError.new(error)
      end
      return false
    end
    true
  end

  def create_collection(name, options = nil)
   col = LibMongoC.database_create_collection(self, name, options, out error)
   unless col
      raise BSON::BSONError.new(error)
   end
   Collection.new col
  end

  def read_prefs
    ReadPrefs.new LibMongoC.database_get_read_prefs(self)
  end

  def read_prefs=(value)
    LibMongoC.database_set_read_prefs(self, value)
  end

  def write_concern
    WriteConcern.new LibMongoC.database_get_write_concern(self)
  end

  def write_concern=(value)
    LibMongoC.database_set_write_concern(self, value)
  end

  def find_collections(filter)
    cur = LibMongoC.database_find_collections(self, filter.to_bson, out error)
    unless cur
      raise BSON::BSONError.new(error)
    end
    Cursor.new cur
  end

  def collection_names
    names = LibMongoC.database_get_collection_names(self, out error)
    unless names
      raise BSON::BSONError.new(error)
    end
    ret = [] of String
    count = 0
    loop do
      cur = names[count]
      break if cur.nil?
      ret << String.new(cur)
      count += 1
    end
    LibBSON.bson_strfreev(names)
    ret
  end

  def collection(name)
    Collection.new LibMongoC.database_get_collection(self, name)
  end

  def [](name)
    collection(name)
  end

  def to_unsafe
    @handle
  end
end
