class Array(T)
  def to_bson(bson = BSON.new)
    each_with_index do |item, i|
      case item
      when Array
        bson.append_array(i.to_s) do |_, child|
          item.to_bson(child)
        end
      when Hash, NamedTuple
        bson.append_document(i.to_s) do |child|
          item.to_bson(child)
        end
      when .responds_to? :to_bson
        bson[i.to_s] = item.to_bson
      else
        bson[i.to_s] = item
      end
    end
    bson
  end

  def self.from_bson(bson : BSON::Field) : self
    {% begin %}
    {% types = T.union_types %}

    arr = self.new

    case bson
    when BSON
      bson.each do |val|
        case v = val.value
        {% for typ in types %}
          {% if typ <= BSON::Serializable || typ.class.has_method? :from_bson %}
          when BSON::Field
            arr << {{ typ }}.from_bson(v)
          {% else %}
          when {{ typ }}
            arr << v.as({{ typ }})
          {% end %}
        {% end %}
        else
          raise Exception.new "Unable to deserialize BSON array '#{{{@type.stringify}}}'."
        end
      end
    else
      raise "Invalid bson"
    end

    arr

    {% end %}
  end
end
