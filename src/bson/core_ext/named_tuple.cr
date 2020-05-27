struct NamedTuple
  def to_bson(bson = BSON.new)
    each do |k, v|
      case v
      when Array
        bson.append_array(k.to_s) do |_appender, child|
          v.to_bson(child)
        end
      when NamedTuple, Hash
        bson.append_document(k.to_s) do |child|
          v.to_bson(child)
        end
      when .responds_to? :to_bson
        bson[k.to_s] = v.to_bson
      else
        bson[k.to_s] = v
      end
    end
    bson
  end
end
