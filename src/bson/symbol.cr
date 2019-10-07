class BSON
  struct Symbol
    @name : String

    getter name

    def initialize(@name)
    end

    def bytesize
      @name.bytesize
    end
    def to_json(json : JSON::Builder)
      json.string name
    end

    def to_unsafe
      @name.to_unsafe
    end
  end
end
