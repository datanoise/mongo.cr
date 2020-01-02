require "./index_opt"
require "./read_prefs"
require "./database"

class Mongo::Collection
  @database : Mongo::Database?
  @handle : LibMongoC::Collection
  @owned : Bool
  @valid : Bool
  getter database

  def initialize(@database, @handle : LibMongoC::Collection, @owned = true)
    raise "invalid handle" unless @handle
    @valid = true
  end

  def initialize(@handle : LibMongoC::Collection, @owned = true)
    raise "invalid handle" unless @handle
    @valid = true
  end

  def invalidate
    @valid = false
    LibMongoC.collection_destroy(@handle)
  end

  def finalize
    LibMongoC.collection_destroy(@handle) if @owned && @valid
  end

  # This method shall execute an aggregation query on the underlying 'Collection'
  def aggregate(pipeline, flags = LibMongoC::QueryFlags::NONE, options = BSON.new, prefs = nil)
    Cursor.new LibMongoC.collection_aggregate(self, flags, pipeline.to_bson, options, prefs)
  end

  # This method shall execute an aggregation query on the underlying 'Collection'
  # The results are passed to the specified block.
  def aggregate(pipeline, flags = LibMongoC::QueryFlags::NONE, options = BSON.new, prefs = nil)
    aggregate(pipeline, flags, options, prefs).each do |doc|
      yield doc
    end
  end

  # This method shall execute a command on a collection.
  def command(command, fields = BSON.new, flags = LibMongoC::QueryFlags::NONE,
              skip = 0, limit = 0, batch_size = 0, prefs = nil)
    Cursor.new LibMongoC.collection_command(self, flags, skip.to_u32,
                                            limit.to_u32, batch_size.to_u32,
                                            command.to_bson, fields.to_bson, prefs)
  end

  # This method shall execute a command on a collection.
  # The results are passed to the specified block.
  def command(command, fields = BSON.new, flags = LibMongoC::QueryFlags::NONE,
              skip = 0, limit = 0, batch_size = 0, prefs = nil)
    command(command, fields, flags, skip, limit, batch_size, prefs).each do |doc|
      yield doc
    end
  end

  # This is a simplified interface to command that returns the first result document.
  def command_simple(command, prefs = nil)
    if LibMongoC.collection_command_simple(self, command.to_bson, prefs, out reply, out error)
        repl = BSON.copy_from pointerof(reply)
        LibBSON.bson_destroy(pointerof(reply))
        repl
    else
      raise BSON::BSONError.new(pointerof(error))
    end
  end

  # Counts the number of documents matching the specified criteria.
  def count(query = BSON.new, flags = LibMongoC::QueryFlags::NONE,
            skip = 0, limit = 0, opts = nil, prefs = nil)
    if opts
      ret = LibMongoC.collection_count_with_opts(self, flags, query.to_bson, skip.to_i64,
                                                 limit.to_i64, opts.to_bson, prefs, out error1)
      raise BSON::BSONError.new(pointerof(error1)) if ret == -1
      ret
    else
      ret = LibMongoC.collection_count(self, flags, query.to_bson, skip.to_i64, limit.to_i64, prefs, out error2)
      raise BSON::BSONError.new(pointerof(error2)) if ret == -1
      ret
    end
  end

  # This method requests that a collection be dropped, including all indexes
  # associated with the collection.
  def drop
    unless LibMongoC.collection_drop(self, out error)
      raise BSON::BSONError.new(pointerof(error))
    end
  end

  # This method requests to drop an index named `index_name`.
  def drop_index(index_name)
    unless LibMongoC.collection_drop_index(self, index_name, out error)
      raise BSON::BSONError.new(pointerof(error))
    end
  end

  # This method will request the creation of a new index.
  def create_index(keys, opt = IndexOpt.new)
    unless LibMongoC.collection_create_index(self, keys.to_bson, opt, out error)
      raise BSON::BSONError.new(pointerof(error))
    end
  end

  # Fetches a cursor containing documents, each corresponding to an index on
  # this collection.
  def find_indexes
    unless cursor = LibMongoC.collection_find_indexes(self, out error)
      raise BSON::BSONError.new(pointerof(error))
    end
    Cursor.new cursor
  end

  # Fetches a cursor containing documents, each corresponding to an index on
  # this collection.
  # The results are passed to the specified block.
  def find_indexes
    find_indexes.each do |doc|
      yield doc
    end
  end

  # This method shall execute a query on the underlying collection.
  # If no options are necessary, query can simply contain a query such as
  # {a:1}. If you would like to specify options such as a sort order, the query
  # must be placed inside of {"$query": {}} as specified by the server
  # documentation.
  def find(query, fields = BSON.new, flags = LibMongoC::QueryFlags::NONE,
           skip = 0, limit = 0, batch_size = 0, prefs = nil)
    Cursor.new LibMongoC.collection_find(self, flags, skip.to_u32, limit.to_u32, batch_size.to_u32,
                                         query.to_bson, fields.to_bson, prefs)
  end

  # This method shall execute a query on the underlying collection.
  # If no options are necessary, query can simply contain a query such as
  # {a:1}. If you would like to specify options such as a sort order, the query
  # must be placed inside of {"$query": {}} as specified by the server
  # documentation.
  # The results are passed to the specified block.
  def find(query, fields = BSON.new, flags = LibMongoC::QueryFlags::NONE,
           skip = 0, limit = 0, batch_size = 0, prefs = nil)
    find(query, fields, flags, skip, limit, batch_size, prefs).each do |doc|
      yield doc
    end
  end

  # The same as `find` but returns a first document from the cursor.
  def find_one(query, fields = BSON.new, flags = LibMongoC::QueryFlags::NONE,
               skip = 0, prefs = nil)
    cursor = find(query, fields, flags, skip: skip, prefs: prefs)
    cursor.next.tap do
      cursor.close
    end
  end

  # This method shall insert document into collection.  If no _id element is
  # found in document, then a Oid will be generated locally and added to the
  # document.  You can retrieve a generated _id from `last_error` method.
  def insert(document, flags = LibMongoC::InsertFlags::NONE, write_concern = nil)
    unless LibMongoC.collection_insert(self, flags, document.to_bson, write_concern, out error)
      raise BSON::BSONError.new(pointerof(error))
    end
  end

  def insert_bulk(documents, flags = LibMongoC::InsertFlags::NONE, write_concern = nil)
    return if documents.empty?

    docs = Pointer(LibBSON::BSON).malloc(documents.size) {|idx| documents[idx].to_bson.to_unsafe}
    unless LibMongoC.collection_insert_bulk(self, flags, docs, documents.size.to_u32, write_concern, out error)
      raise BSON::BSONError.new(pointerof(error))
    end
  end

  # This method shall update documents in collection that match selector.  By
  # default, updates only a single document. Set flags to `UPDATE_MULTI_UPDATE`
  # to update multiple documents.
  def update(selector, update, flags = LibMongoC::UpdateFlags::NONE, write_concern = nil)
    unless LibMongoC.collection_update(self, flags, selector.to_bson, update.to_bson, write_concern, out error)
      raise BSON::BSONError.new(pointerof(error))
    end
  end

  # This method shall save a document into collection. If the document has an
  # _id field it will be updated. Otherwise it will be inserted.
  def save(document, write_concern = nil)
    unless LibMongoC.collection_save(self, document.to_bson, write_concern, out error)
      raise BSON::BSONError.new(pointerof(error))
    end
  end

  # This method shall remove documents in the given collection that match
  # selector. The `BSON` selector is not validated, simply passed along as
  # appropriate to the server. As such, compatibility and errors should be
  # validated in the appropriate server documentation.
  def remove(selector, flags = LibMongoC::RemoveFlags::NONE, write_concern = nil)
    unless LibMongoC.collection_remove(self, flags, selector.to_bson, write_concern, out error)
      raise BSON::BSONError.new(pointerof(error))
    end
  end

  # This method is a helper to rename an existing collection on a MongoDB
  # server. The name of the collection will also be updated internally so it is
  # safe to continue using this collection after the rename. Additional
  # operations will occur on renamed collection.
  def rename(new_db, new_name, drop_target_before_rename = false)
    unless LibMongoC.collection_rename(self, new_db, new_name, drop_target_before_rename, out error)
      raise BSON::BSONError.new(pointerof(error))
    end
  end

  # Update and return an object.
  # This is a thin wrapper around the `findAndModify` command. Either `update`
  # or `remove` arguments are required.
  def find_and_modify(query, update, sort = nil, fields = nil, remove = false, upsert = false, new = false)
    unless LibMongoC.collection_find_and_modify(self, query.to_bson, sort.to_bson,
        update.to_bson, fields.to_bson, remove, upsert, new, out reply, out error)
      raise BSON::BSONError.new(pointerof(error))
    end
    doc = BSON.copy_from pointerof(reply)
	LibBSON.bson_destroy(pointerof(reply))
    value = doc["value"]
    doc.invalidate
    return nil unless value.is_a?(BSON)
    value
  end

  # This method is a helper to retrieve statistics about the collection.
  def stats(options = nil)
    unless LibMongoC.collection_stats(self, options.to_bson, out reply, out error)
      raise BSON::BSONError.new(pointerof(error))
    end
    repl = BSON.copy_from pointerof(reply)
    LibBSON.bson_destroy(pointerof(reply))
    repl
  end

  # Fetches the default read preferences to use for collection. Operations
  # without specified read-preferences will default to this.
  def read_prefs
    ReadPrefs.new LibMongoC.collection_get_read_prefs(self)
  end

  # Sets the default read preferences to use for operations on collection not
  # specifying a read preference.
  def read_prefs=(value)
    LibMongoC.collection_set_read_prefs(self, value)
  end

  # Fetches the default write concern to be used on write operations
  # originating from collection and not specifying a write concern.
  def write_concern
    WriteConcern.new LibMongoC.collection_get_write_concern(self)
  end

  # Sets the default write concern to use for operations on collection not
  # specifying a write concern.
  def write_concern=(write_concern)
    LibMongoC.collection_set_write_concern(self, write_concern)
  end

  # Fetches the name of collection.
  def name
    String.new LibMongoC.collection_get_name(self)
  end

  # This method shall return `getLastError` document, according to write_concern
  # on last executed command for current collection instance.
  def last_error
    if handle = LibMongoC.collection_get_last_error(self)
      BSON.new(handle)
    end
  end

  # This method shall returns the canonical stringification, as used in
  # `create_index` without an explicit name, of a given key specification.  It
  # is a programming error to call this function on a non-standard index, such
  # one other than a straight index with ascending and descending.
  def self.keys_to_index_string(keys)
    String.new LibMongoC.collection_keys_to_index_string(keys)
  end

  # This method is a helper function to execute the validate MongoDB command.
  # Currently, the only supported options are full, which is a boolean and
  # scandata, also a boolean. See the MongoDB documentation for more
  # information on this command.
  def validate(options = nil)
    unless LibMongoC.collection_validate(self, options.to_bson, out reply, out error)
      raise BSON::BSONError.new(pointerof(error))
    end
    repl = BSON.copy_from pointerof(reply)
    LibBSON.bson_destroy(pointerof(reply))
    repl
  end

  # This method shall begin a new bulk operation. Use returned `BulkOperation`
  # object to schedule different database operations and execute them all at
  # once.
  #
  # @param ordered: if is `true`, then the bulk operation will attempt to
  # continue processing even after the first failure.  @param write_concern:
  # should contain the write concern you wish to have applied to all operations
  # within the bulk operation.
  def create_bulk_operation(ordered = false, write_concern = nil)
    BulkOperation.new LibMongoC.collection_create_bulk_operation(self, ordered, write_concern)
  end

  def to_unsafe
    @handle
  end
end
