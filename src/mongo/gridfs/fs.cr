require "../database"

class Mongo::GridFS::FS
  @database : Mongo::Database
  @handle : LibMongoC::GridFS

  getter database

  def initialize(@database, @handle : LibMongoC::GridFS)
    raise "invalid handle" unless @handle
  end

  def finalize
    LibMongoC.gridfs_destroy(self)
  end

  # This function shall create a new file.
  def create_file(filename, content_type = nil, md5 = nil, aliases = BSON.new, metadata = BSON.new, chunk_size = 0)
    opt = LibMongoC::GFSFileOpt.new
    opt.md5 = md5.to_unsafe if md5
    opt.filename = filename.to_unsafe
    opt.content_type = content_type.to_unsafe if content_type
    opt.aliases = aliases.to_unsafe
    opt.metadata = metadata.to_unsafe
    opt.chunk_size = chunk_size.to_u32

    File.new LibMongoC.gridfs_create_file(self, pointerof(opt))
  end

  # Requests that an entire GridFS be dropped, including all files associated
  # with it.
  def drop
    unless LibMongoC.gridfs_drop(self, out error)
      raise BSON::BSONError.new(pointerof(error))
    end
  end

  # Finds all gridfs files matching query. You can iterate the matched gridfs
  # files with the resulting file list.
  def find(query = BSON.new)
    FileList.new LibMongoC.gridfs_find(self, query.to_bson)
  end

  # This function shall execute a query on the underlying gridfs
  # implementation. The first file matching query will be returned.
  def find_one(query = BSON.new)
    handle = LibMongoC.gridfs_find_one(self, query.to_bson, out error)
    # unless handle
    #   raise BSON::BSONError.new(pointerof(error))
    # end
    File.new handle if handle
  end

  # Finds the first file matching the filename specified. If no file could be
  # found, nil is returned.
  def find_by_name(filename)
    handle = LibMongoC.gridfs_find_one_by_filename(self, filename, out error)
    # unless handle
    #   raise BSON::BSONError.new(pointerof(error))
    # end
    File.new handle if handle
  end

  # Returns a Collection that contains the chunks for files.
  def chunks
    Collection.new @database, LibMongoC.gridfs_get_chunks(self), false
  end

  # Retrieves the Collection containing the file metadata for GridFS.
  def files
    Collection.new @database, LibMongoC.gridfs_get_files(self), false
  end

  # Removes all files matching filename and their data chunks from the MongoDB
  # server.
  def remove(filename)
    unless LibMongoC.gridfs_remove_by_filename(self, filename, out error)
      raise BSON::BSONError.new(pointerof(error))
    end
  end

  def to_unsafe
    @handle
  end
end
