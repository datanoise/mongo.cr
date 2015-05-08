require "./uri"

class Mongo::Client
  def initialize(@handle = LibMongoC::Client)
    unless @handle
      raise "Unable to initialize Client"
    end
  end

  def initialize(uri: String | Uri)
    handle =
      if uri.is_a?(String)
        LibMongoC.client_new(uri)
      else
        LibMongoC.client_new_from_uri(uri)
      end
    initialize handle
  end

  def uri
    Uri.new LibMongoC.client_get_uri(self)
  end

  def command(db_name, query, fields = BSON.new, flags = LibMongoC::QueryFlags::QUERY_NONE,
              skip = 0, limit = 0, batch_size = 0, prefs = nil)
    Cursor.new LibMongoC.client_command(self, db_name, flags, skip.to_u32, limit.to_u32, batch_size.to_u32,
                                        query, fields, prefs)
  end

  def kill_cursor(cursor_id)
    LibMongoC.client_kill_cursor(self, cursor_id.to_i64)
  end

  def command_simple(db_name, command, prefs = nil)
    unless LibMongoC.client_command_simple(self, db_name, command, prefs, out reply, out error)
      raise BSON::BSONError.new(error)
    end
    BSON.copy_from pointerof(reply)
  end

  def database(name)
    Database.new LibMongoC.client_get_database(self, name)
  end

  def [](name)
    database(name)
  end

  def collection(db_name, collection_name)
    Collection.new LibMongoC.client_get_collection(self, db_name, collection_name)
  end

  def database_names
    names = LibMongoC.client_get_database_names(self, out error)
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

  def find_databases
    cur = LibMongoC.client_find_databases(self, out error)
    puts cur
    unless cur
      raise BSON::BSONError.new(error)
    end
    Cursor.new cur
  end

  def server_status(prefs = nil)
    unless LibMongoC.client_get_server_status(self, prefs, out reply, out error)
      raise BSON::BSONError.new(error)
    end
    BSON.copy_from pointerof(reply)
  end

  def max_message_size
    LibMongoC.client_get_max_message_size(self)
  end

  def max_bson_size
    LibMongoC.client_get_max_bson_size(self)
  end

  def write_concern
    WriteConcern.new LibMongoC.client_get_write_concern(self)
  end

  def write_concern=(write_concern)
    LibMongoC.client_set_write_concern(self, write_concern)
  end

  def read_prefs
    ReadPrefs.new LibMongoC.client_get_read_prefs(self)
  end

  def read_prefs=(value: ReadPrefs)
    LibMongoC.client_set_read_prefs(self, value)
  end

  def finalize
    LibMongoC.client_destroy(self)
  end

  def to_unsafe
    @handle
  end
end
