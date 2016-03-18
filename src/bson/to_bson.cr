{% for type in [Int32, Int64, Bool, Float64, Float32, Nil, Time] %}
  struct {{type}}
    def to_bson(appender)
      appender << self
    end
  end
{% end %}

{% for type in %w(Symbol MinKey MaxKey ObjectId Timestamp Code Binary) %}
  struct BSON::{{type.id}}
    def to_bson(appender)
      appender << self
    end
  end
{% end %}

{% for type in [String, BSON, Regex] %}
  class {{type}}
    def to_bson(appender)
      appender << self
    end
  end
{% end %}

struct Nil
  def to_bson
    self
  end
end

struct Symbol
  def to_bson(appender)
    appender << BSON::Symbol.new(self.to_s)
  end
end

class Array(T)
  def to_bson
    BSON.build_array do |array|
      each do |value|
        array << value
      end
    end
  end

  def to_bson(appender)
    appender.array do |array|
      each do |value|
        array << value
      end
    end
  end
end

class Hash(K, V)
  def to_bson
    BSON.build do |doc|
      each do |k, v|
        doc.field(k.to_s, v)
      end
    end
  end

  def to_bson(appender)
    appender.document do |doc|
      each do |k, v|
        doc.field(k.to_s, v)
      end
    end
  end
end
