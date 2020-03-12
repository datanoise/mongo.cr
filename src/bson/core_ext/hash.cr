require "json"
class Hash(K, V)
  def to_bson(bson = BSON.new)
    #return BSON.from_json(self.to_json)
    each do |k, v|
      case v
      when Array
        bson.append_array(k) do |appender, child|
          v.to_bson(child)
        end
      when Hash
        bson.append_document(k) do |child|
          v.to_bson(child)
        end
      else
        bson[k] = v
      end
    end
    bson
  end
end