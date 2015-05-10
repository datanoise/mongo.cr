class Array(T)
  def to_bson(bson = BSON.new)
    each_with_index do |item, i|
      case item
      when Array
        bson.append_array(i.to_s) do |appender, child|
          item.to_bson(child)
        end
      when Hash
        bson.append_document(i.to_s) do |child|
          item.to_bson(child)
        end
      else
        bson[i.to_s] = item
      end
    end
    bson
  end
end