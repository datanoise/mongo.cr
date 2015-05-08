require "../bson/bson"
require "./index_opt"
require "./read_prefs"

class Mongo::Collection
  def initialize(@handle: LibMongoC::Collection)
  end

  def finalize
    LibMongoC.collection_destroy(self)
  end

  def aggregate(pipeline, flags = LibMongoC::QueryFlags::QUERY_NONE,
                options = BSON.new, prefs = nil)
    Cursor.new LibMongoC.collection_aggregate(self, flags, pipeline.to_bson, options, prefs)
  end

  def command(command, fields, flags = LibMongoC::QueryFlags::QUERY_NONE,
              skip = 0, limit = 0, batch_size = 0, prefs = nil)
    Cursor.new LibMongoC.collection_command(self, flags, skip.to_u32,
                                            limit.to_u32, batch_size.to_u32,
                                            command.to_bson, fields.to_bson, prefs)
  end

  def command_simple(command, prefs = nil)
    if LibMongoC.collection_command_simple(self, command.to_bson, out reply, out error)
      BSON.copy_from pointerof(reply)
    else
      raise BSON::BSONError.new(error)
    end
  end

  def count(query = BSON.new, flags = LibMongoC::QueryFlags::QUERY_NONE,
            skip = 0, limit = 0, opts = nil, prefs = nil)
    ret =
      if opts
        LibMongoC.collection_count_with_opts(self, flags, query.to_bson, skip.to_i64,
                                             limit.to_i64, opts.to_bson, prefs, out error)
      else
        LibMongoC.collection_count(self, flags, query.to_bson, skip.to_i64, limit.to_i64, prefs, out error)
      end
    if ret == -1
      raise BSON::BSONError.new(error)
    end
    ret
  end

  def drop
    unless LibMongoC.collection_drop(self, out error)
      raise BSON::BSONError.new(error)
    end
  end

  def drop_index(index_name)
    unless LibMongoC.collection_drop_index(self, index_name, out error)
      raise BSON::BSONError.new(error)
    end
  end

  def create_index(keys, opt = IndexOpt.new)
    unless LibMongoC.collection_create_index(self, keys.to_bson, opt, out error)
      raise BSON::BSONError.new(error)
    end
  end

  def ensure_index(keys, opt = IndexOpt.new)
    unless LibMongoC.collection_ensure_index(self, keys.to_bson, opt, out error)
      raise BSON::BSONError.new(error)
    end
  end

  def find_indexes()
    unless cursor = LibMongoC.collection_find_indexes(self, out error)
      raise BSON::BSONError.new(error)
    end
    Cursor.new cursor
  end

  def find(query, fields = BSON.new, flags = LibMongoC::QueryFlags::QUERY_NONE, skip = 0, limit = 0,
           batch_size = 0, prefs = nil)
    Cursor.new LibMongoC.collection_find(self, flags, skip.to_u32, limit.to_u32, batch_size.to_u32,
                                         query.to_bson, fields.to_bson, prefs)
  end

  def insert(document, flags = LibMongoC::QueryFlags::QUERY_NONE, write_concern = nil)
    unless LibMongoC.collection_insert(self, flags, document.to_bson, write_concern, out error)
      raise BSON::BSONError.new(error)
    end
  end

  def insert_bulk(documents, flags = LibMongoC::QueryFlags::QUERY_NONE, write_concern = nil)
    return if documents.empty?

    docs = Pointer(LibBSON::BSON).malloc(documents.length) {|idx| documents[idx].to_bson.to_unsafe}
    unless LibMongoC.collection_insert_bulk(self, flags, docs, documents.length.to_u32, write_concern, out error)
      raise BSON::BSONError.new(error)
    end
  end

  def update(selector, update, flags = LibMongoC::QueryFlags::QUERY_NONE, write_concern = nil)
    unless LibMongoC.collection_update(self, flags, selector.to_bson, update.to_bson, write_concern, out error)
      raise BSON::BSONError.new(error)
    end
  end

  def delete(selector, flags = LibMongoC::DeleteFlags::DELETE_NONE, write_concern = nil)
    unless LibMongoC.collection_delete(self, flags, selector.to_bson, write_concern, out error)
      raise BSON::BSONError.new(error)
    end
  end

  def save(document, write_concern = nil)
    unless LibMongoC.collection_save(self, document.to_bson, write_concern, out error)
      raise BSON::BSONError.new(error)
    end
  end

  def remove(selector, flags = LibMongoC::RemoveFlags::REMOVE_NONE, write_concern = nil)
    unless LibMongoC.collection_remove(self, flags, selector.to_bson, write_concern, out error)
      raise BSON::BSONError.new(error)
    end
  end

  def rename(new_db, new_name, drop_target_before_rename = false)
    unless LibMongoC.collection_rename(self, new_db, new_name, drop_target_before_rename, out error)
      raise BSON::BSONError.new(error)
    end
  end

  def find_and_modify(query, update, sort = nil, fields = nil, remove = false, upsert = false, new = false)
    unless LibMongoC.collection_find_and_modify(self, query.to_bson, sort.to_bson,
        update.to_bson, fields.to_bson, remove, upsert, new, out reply, out error)
      raise BSON::BSONError.new(error)
    end
    BSON.copy_from pointerof(reply)
  end

  def stats(options = nil)
    unless LibMongoC.collection_stats(self, options.to_bson, out reply, out error)
      raise BSON::BSONError.new(error)
    end
    BSON.copy_from pointerof(reply)
  end

  def read_prefs
    ReadPrefs.new LibMongoC.collection_get_read_prefs(self)
  end

  def read_prefs=(value)
    LibMongoC.collection_set_read_prefs(self, read_prefs)
  end

  def write_concern
    WriteConcern.new LibMongoC.collection_get_write_concern(self)
  end

  def write_concern=(write_concern)
    LibMongoC.collection_set_write_concern(self, write_concern)
  end

  def name
    String.new LibMongoC.collection_get_name(self)
  end

  def last_error
    if handle = LibMongoC.collection_get_last_error(self)
      BSON.new(handle)
    end
  end

  def self.keys_to_index_string(keys)
    String.new LibMongoC.collection_keys_to_index_string(keys)
  end

  def validate(options = nil)
    unless LibMongoC.collection_validate(self, options.to_bson, out reply, out error)
      raise BSON::BSONError.new(error)
    end
    BSON.copy_from pointerof(reply)
  end

  def to_unsafe
    @handle
  end
end
