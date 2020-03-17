class Hash(K, V)
  def to_bson(bson = BSON.new)
    each do |k, v|
      case v
      when Array
        bson.append_array(k) do |_, child|
          v.to_bson(child)
        end
      when NamedTuple, Hash
        bson.append_document(k) do |child|
          v.to_bson(child)
        end
      when .responds_to? :to_bson
        bson[k] = v.to_bson
      else
        bson[k] = v
      end
    end
    bson
  end

  def self.from_bson(bson : BSON::Field) : self
    {% begin %}
    {% types = V.union_types %}

    hash = self.new

    case bson
    when BSON
      bson.each_pair do |k, val|
        case v = val.value
        {% for typ in types %}
          {% if typ <= BSON::Serializable || typ.class.has_method? :from_bson %}
          when BSON::Field
            hash[k] = {{ typ }}.from_bson(v)
          {% else %}
          when {{ typ }}
            hash[k] = v.as({{typ}})
          {% end %}
        {% end %}
        else
          raise Exception.new "Unable to deserialize key '#{k}' for hash '#{{{@type.stringify}}}'."
        end
      end
    else
      raise "Invalid bson"
    end

    hash

    {% end %}
  end
end
