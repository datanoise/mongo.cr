class BSON
  class ArrayBuilder
    getter bson
    def initialize(@bson = BSON.new)
      @index = 0
    end

    def <<(value)
      push(value)
    end

    def push(value)
      push { |appender| value.to_bson(appender) }
    end

    def push
      appender = Appender.new(@index, @bson)
      yield appender
      @index += 1 if appender.appended?
    end
  end
end
