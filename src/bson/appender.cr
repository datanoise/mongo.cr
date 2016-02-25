class BSON
  class Appender
    getter? appended
    def initialize(key, @bson)
      @key = key.to_s
      @appended = false
    end

    def document
      raise "already appended a value" if appended?

      unless LibBSON.bson_append_document_begin(@bson, @key, @key.bytesize, out child_handle)
        return false
      end
      child = BSON.new(pointerof(child_handle))
      begin
        yield Builder.new(child)
      ensure
        LibBSON.bson_append_document_end(@bson, child)
        child.invalidate
        @appended = true
      end
    end

    def array
      raise "already appended a value" if appended?

      unless LibBSON.bson_append_array_begin(@bson, @key, @key.bytesize, out child_handle)
        return false
      end

      child = BSON.new(pointerof(child_handle))
      begin
        yield ArrayBuilder.new(child)
      ensure
        LibBSON.bson_append_array_end(@bson, child)
        child.invalidate
        @appended = true
      end
    end

    def <<(value)
      raise "already appended a value" if appended?
      @bson[@key] = value
    ensure
      @appended = true
    end
  end
end
