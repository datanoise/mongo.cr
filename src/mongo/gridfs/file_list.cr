class Mongo::GridFS::FileList
  include Enumerable(File)

  def initialize(@handle : LibMongoC::GFSFileList)
    raise "invalid handle" unless @handle
  end

  def finalize
    LibMongoC.gridfs_file_list_destroy(self)
  end

  def next
    handle = LibMongoC.gridfs_file_list_next(self)
    check_error
    File.new handle if handle
  end

  def each
    while file = self.next
      yield file
    end
  end

  def check_error
    if LibMongoC.gridfs_file_list_error(self, out error)
      raise BSON::BSONError.new(pointerof(error))
    end
  end

  def to_unsafe
    @handle
  end
end
