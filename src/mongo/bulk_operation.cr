require "./lib_mongo"

# This class provides an abstraction for submitting multiple write operations
# as a single batch.
class Mongo::BulkOperation
  def initialize(@handle : LibMongoC::BulkOperation)
    raise "invalid handle" unless @handle
    @executed = false
  end

  def finalize
    LibMongoC.bulk_operation_destroy(@handle)
    self
  end

  # Queue an insert of a single document into a bulk operation. The insert is
  # not performed until `execute` is called.
  def insert(document)
    LibMongoC.bulk_operation_insert(self, document.to_bson)
    self
  end

  # This method queues a delete operation as part of bulk that will delete
  # all documents matching selector. To delete a single document, see
  # `remove_one`.
  def remove(selector)
    LibMongoC.bulk_operation_remove(self, selector.to_bson)
    self
  end

  # This method queues a delete operation as part of bulk that will delete a
  # single document matching selector. To delete a multiple documents, see
  # `remove`.
  def remove_one(selector)
    LibMongoC.bulk_operation_remove_one(self, selector.to_bson)
    self
  end

  # Replace a single document as part of a bulk operation. This only queues the
  # operation. To execute it, call `execute`.
  def replace_one(selector, document, upsert = false)
    LibMongoC.bulk_operation_replace_one(self, selector.to_bson, document.to_bson, upsert)
    self
  end

  # This method queues an update as part of a bulk operation. This does not
  # execute the operation. To execute the entirety of the bulk operation call
  # `execute`.
  def update(selector, document, upsert = false)
    LibMongoC.bulk_operation_update(self, selector.to_bson, document.to_bson, upsert)
    self
  end

  # This method queues an update as part of a bulk operation. It will only
  # modify a single document on the MongoDB server. This method does not
  # execute the operation. To execute the entirety of the bulk operation call
  # `execute`.
  def update_one(selector, document, upsert = false)
    LibMongoC.bulk_operation_update_one(self, selector.to_bson, document.to_bson, upsert)
    self
  end

  # This method executes all operations queued into the bulk operation. If
  # `ordered` was specified to `Collection#create_bulk_operation`, then forward
  # progress will be stopped upon the first error.
  #
  # It is only valid to call `execute` once. This object will be invalidated
  # afterwards.
  def execute
    hint = LibMongoC.bulk_operation_execute(self, out reply, out error)
    @executed = true
    if hint == 0
      raise BSON::BSONError.new(pointerof(error))
    end
    BSON.copy_from pointerof(reply)
  end

  def to_unsafe
    raise "BulkOperation is already executed" if @executed
    @handle
  end
end
