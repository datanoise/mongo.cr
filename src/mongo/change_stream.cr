require "./lib_mongo"

class Mongo::ChangeStream
  def initialize(@handle : LibMongoC::ChangeStream)
    unless @handle
      raise "Unable to initialize ChangeStream"
    end
    @data = Pointer(LibBSON::BSON).malloc(1)
    @closed = false
  end

  def finalize
    close
  end

  def close
    return if @closed
    LibMongoC.change_stream_destroy(self)
    @closed = true
  end

  private def check_closed
    raise "change stream is closed" if @closed
  end

  def next
    check_closed
    if LibMongoC.change_stream_next(self, @data)
      @current = BSON.copy_from @data.value
    else
      check_error
    end
  end

  def get_resume_token
    check_closed
    LibMongoC.change_stream_get_resume_token(self)
  end

  def current
    check_closed
    @current
  end

  private def check_error
    if LibMongoC.change_stream_error_document(self, out error, out reply)
      raise BSON::BSONError.new(pointerof(error))
    end
  end

  def to_unsafe
    check_closed
    @handle
  end
end
