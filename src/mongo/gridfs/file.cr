class Mongo::GridFS::File < IO
  #include IO
  # breaking change moved IO from module to class in release 0.24.1

  property! timeout_msec

  def initialize(@handle : LibMongoC::GFSFile, @timeout_msec = 5000_u32)
    raise "invalid handle" unless @handle
  end

  def finalize
    LibMongoC.gridfs_file_destroy(@handle)
  end

  # Fetches the aliases associated with a gridfs file.
  def aliases
    handle = LibMongoC.gridfs_file_get_aliases(self)
    BSON.new handle if handle
  end

  # Sets the aliases for a gridfs file.
  # You need to call `save` to persist this change.
  def aliases=(value)
    handle = LibMongoC.gridfs_file_set_aliases(self, value.to_bson)
    BSON.new handle if handle
  end

  # Fetches the chunk size used with the underlying gridfs file.
  def chunk_size
    LibMongoC.gridfs_file_get_chunk_size(self)
  end

  # Fetches the content type specified for the underlying file.
  def content_type
    handle = LibMongoC.gridfs_file_get_content_type(self)
    handle ? String.new handle : ""
  end

  # Sets the content type for the gridfs file. This should be something like
  # "text/plain".
  # You need to call `save` to persist this change.
  def content_type=(value)
    LibMongoC.gridfs_file_set_content_type(self, value)
  end

  # Fetches the filename for the give gridfs file.
  def name
    handle = LibMongoC.gridfs_file_get_filename(self)
    handle ? String.new handle : ""
  end

  # Sets the filename for value.
  # You need to call `save` to persist this change.
  def name=(value)
    LibMongoC.gridfs_file_set_filename(self, value)
  end

  # Fetches the length of the gridfs file in bytes.
  def length
    LibMongoC.gridfs_file_get_length(self)
  end

  # Fetches the pre-computed MD5 for the underlying gridfs file.
  def md5
    handle = LibMongoC.gridfs_file_get_md5(self)
    handle ? String.new handle : ""
  end

  # Sets the MD5 checksum for file.
  # You need to call `save` to persist this change.
  def md5=(value)
    LibMongoC.gridfs_file_set_md5(self, value)
  end

  # Fetches a bson document containing the metadata for the gridfs file.
  def metadata
    handle = LibMongoC.gridfs_file_get_metadata(self)
    BSON.new handle if handle
  end

  # Sets the metadata associated with file.
  # You need to call `save` to persist this change.
  def metadata=(value)
    LibMongoC.gridfs_file_set_metadata(self, value.to_bson)
  end

  # Fetches the specified upload date of the gridfs file.
  def upload_date
    epoch = LibMongoC.gridfs_file_get_upload_date(self)
    spec = LibC::Timespec.new
    spec.tv_sec = epoch / 1000
    Time.new(spec, Time::Location::UTC)
  end

  # Removes file and its data chunks from the MongoDB server.
  def remove
    LibMongoC.gridfs_file_remove(self, out error).tap do |res|
      raise BSON::BSONError.new(pointerof(error)) unless res
    end
  end

  # Saves modifications to file to the MongoDB server.
  def save
    LibMongoC.gridfs_file_save(self).tap do
      check_error
    end
  end

  # This function seeks within the underlying file.
  def seek(amount, whence = LibC::SEEK_SET)
    LibMongoC.gridfs_file_seek(self, amount.to_i64, whence).tap do
      check_error
    end
  end

  # This function returns the current position indicator within file.
  def tell
    LibMongoC.gridfs_file_tell(self).tap do
      check_error
    end
  end

  # This function performs a scattered read from file, potentially blocking to
  # read from the MongoDB server.
  def read(slice : Slice(UInt8))
    iov = LibMongoC::IOVec.new
    iov.ion_base = slice.to_unsafe
    iov.ion_len = slice.bytesize.to_u64

    len = LibMongoC.gridfs_file_readv(self, pointerof(iov),
                                      LibC::SizeT.new(1),
                                      LibC::SizeT.new(0),
                                      @timeout_msec.to_u32)
    check_error
    len
  end

  # Performs a gathered write to the underlying gridfs file.
  def write(slice : Slice(UInt8))
    iov = LibMongoC::IOVec.new
    iov.ion_base = slice.to_unsafe
    iov.ion_len = slice.bytesize.to_u64

    len = LibMongoC.gridfs_file_writev(self, pointerof(iov),
                                       LibC::SizeT.new(1),
                                       @timeout_msec.to_u32)
    check_error
    len
  end

  private def check_error
    if LibMongoC.gridfs_file_error(@handle, out error)
      raise BSON::BSONError.new(pointerof(error))
    end
  end

  def to_s(io)
    io << name
  end

  def inspect(io)
    io << "GridFS::File "
    io << "name: #{name}, "
    io << "aliases: #{aliases}, "
    io << "content_type: #{content_type}, "
    io << "length: #{length}, "
    io << "md5: #{md5}, "
    io << "metadata: #{metadata}, "
    io << "upload_date: #{upload_date.to_local}"
  end

  def to_unsafe
    @handle
  end
end
