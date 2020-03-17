struct JSON::Any
  def to_bson
    BSON.from_json self.to_json
  end

  def self.from_bson(bson : BSON::Field)
    case bson
    when Bool
    when Int64
    when Float64
    when String
      self.from_json bson
    when BSON
      self.from_json bson.to_json
    else
      raise "invalid bson"
    end
  end
end
