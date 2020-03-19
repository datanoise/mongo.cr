struct JSON::Any
  def to_bson
    BSON.from_json self.to_json
  end

  def self.from_bson(bson : BSON::Field) : self
    case bson
    when Bool
      self.new bson
    when Int64
      self.new bson
    when Float64
      self.new bson
    when String
      self.new bson
    when BSON
      JSON.parse bson.to_json
    else
      raise "invalid bson"
    end
  end
end
