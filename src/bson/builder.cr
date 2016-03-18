class BSON
  class Builder
    getter bson

    def initialize(@bson = BSON.new)
    end

    def field(key, value)
      field(key) { |appender| value.to_bson(appender) }
    end

    def field(key)
      appender = Appender.new(key, @bson)
      yield appender
      appender << nil unless appender.appended?
    end
  end
end
