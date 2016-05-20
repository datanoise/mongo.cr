class BSON
  struct Iter
    @bson : BSON

    include Iterator(Value)

    def initialize(@bson)
      @iter = Pointer(LibBSON::Iter).malloc(1)
      rewind
    end

    def next
      return stop unless LibBSON.bson_iter_next(@iter)
      Value.new(LibBSON.bson_iter_value(@iter))
    end

    def rewind
      LibBSON.bson_iter_init(@iter, @bson)
      self
    end
  end

  struct IterPair
    @bson : BSON

    include Iterator(Value)

    def initialize(@bson)
      @iter = Pointer(LibBSON::Iter).malloc(1)
      rewind
    end

    def next
      return stop unless LibBSON.bson_iter_next(@iter)
      key = LibBSON.bson_iter_key(@iter)
      val = LibBSON.bson_iter_value(@iter)
      {String.new(key), Value.new(val)}
    end

    def rewind
      LibBSON.bson_iter_init(@iter, @bson)
      self
    end
  end

  struct IterKey
    @bson : BSON

    include Iterator(String)

    def initialize(@bson)
      @iter = Pointer(LibBSON::Iter).malloc(1)
      rewind
    end

    def next
      return stop unless LibBSON.bson_iter_next(@iter)
      String.new LibBSON.bson_iter_key(@iter)
    end

    def rewind
      LibBSON.bson_iter_init(@iter, @bson)
      self
    end
  end
end
