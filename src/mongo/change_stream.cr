require "./lib_mongo"

class Mongo::ChangeStream
  def initialize(@handle : LibMongoC::ChangeStream)
    unless @handle
      raise "Unable to initialize ChangeStream"
    end
    @data = Pointer(LibBSON::BSON).malloc(1)
  end

  include Enumerable(BSON)

  def finalize
    LibMongoC.change_stream_destroy(self)
    @data.clear(1)
  end

  # This method shall iterate the underlying changestream, setting `BSON` to the
  # next document.
  # It returns `nil` if the cursor was exhausted.
  def next
    if LibMongoC.change_stream_next(self, @data)
      check_error
      @current = BSON.copy_from @data.value
    end
  end

  def get_resume_token
    next_token = LibMongoC.change_stream_get_resume_token(self)
    check_error
    BSON.copy_from pointerof(next_token.value)
  end

  # This method iterates the underlying cursor passing the resulted documents
  # to the specified block.
  def each
    while v = self.next
      yield v
    end
  end

  private def check_error
    if LibMongoC.change_stream_error_document(self, nil, out error)
      raise BSON::BSONError.new(pointerof(error))
    end
  end

  def to_unsafe
    @handle
  end
end
