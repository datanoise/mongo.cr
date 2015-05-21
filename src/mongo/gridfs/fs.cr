class Mongo::GridFS::FS
  getter database

  def initialize(@database, @handle: LibMongoC::GridFS)
    raise "invalid handle" unless @handle
  end

  def finalize
    LibMongoC.gridfs_destroy(self)
  end

  def create_file(filename, content_type = nil, md5 = nil, aliases = BSON.new, metadata = BSON.new, chunk_size = 0)
    opt = LibMongoC::GFSFileOpt.new
    opt.md5 = md5.cstr if md5
    opt.filename = filename.cstr
    opt.content_type = content_type.cstr if content_type
    opt.aliases = aliases.to_unsafe
    opt.metadata = metadata.to_unsafe
    opt.chunk_size = chunk_size.to_u32

    File.new LibMongoC.gridfs_create_file(self, pointerof(opt))
  end

  def drop
    unless LibMongoC.gridfs_drop(self, out error)
      raise BSON::BSONError.new(pointerof(error))
    end
  end

  def find(query = BSON.new)
    FileList.new LibMongoC.gridfs_find(self, query.to_bson)
  end

  def find_one(query = BSON.new)
    handle = LibMongoC.gridfs_find_one(self, query.to_bson, out error)
    # unless handle
    #   raise BSON::BSONError.new(pointerof(error))
    # end
    File.new handle if handle
  end

  def find_by_name(filename)
    handle = LibMongoC.gridfs_find_one_by_filename(self, filename, out error)
    # unless handle
    #   raise BSON::BSONError.new(pointerof(error))
    # end
    File.new handle if handle
  end

  def chunks
    Collection.new @database, LibMongoC.gridfs_get_chunks(self), false
  end

  def files
    Collection.new @database, LibMongoC.gridfs_get_files(self), false
  end

  def remove(filename)
    unless LibMongoC.gridfs_remove_by_filename(self, filename, out error)
      raise BSON::BSONError.new(pointerof(error))
    end
  end

  def to_unsafe
    @handle
  end
end
