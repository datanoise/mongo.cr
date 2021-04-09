class BSON
  struct Code
    @code : String
    @scope : BSON

    getter code
    getter scope

    def initialize(@code, @scope = BSON.new)
    end

    def initialize(handle : LibBSON::Code)
      code = String.new(handle.code, handle.len.to_i32)
      initialize(code)
    end

    def initialize(handle : LibBSON::CodeWScope)
      code = String.new(handle.code, handle.code_len.to_i32)
      scope = BSON.from_data(Slice.new(handle.scope, handle.scope_len.to_i32))
      initialize(code, scope)
    end

    def ==(other : Code)
      code == other.code && scope == other.scope
    end

    def to_json(json : JSON::Builder)
      json.string code
    end

    def ==(other)
      false
    end
  end
end
