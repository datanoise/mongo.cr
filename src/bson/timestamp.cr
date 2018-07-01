class BSON
  struct Timestamp
    include Comparable(Timestamp)

    def initialize(@handle : LibBSON::Timestamp)
    end

    # @param timestamp epoch seconds
    # @param increment in seconds
    def initialize(timestamp : Int, increment)
      handle = LibBSON::Timestamp.new
      handle.ts = timestamp.to_u32
      handle.incr = increment.to_u32
      initialize(handle)
    end

    def timestamp
      @handle.ts
    end

    def increment
      @handle.incr
    end

    def ==(other : Timestamp)
      timestamp == other.timestamp && increment == other.increment
    end

    def ==(other)
      false
    end

    def <=>(other : Timestamp)
      cmp = timestamp <=> other.timestamp
      if cmp == 0
        cmp = increment <=> other.increment
      end
      cmp
    end
  end
end
