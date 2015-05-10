class BSON
  struct Symbol
    getter name

    def initialize(@name)
    end

    def bytesize
      @name.bytesize
    end

    def to_unsafe
      @name.to_unsafe
    end
  end
end