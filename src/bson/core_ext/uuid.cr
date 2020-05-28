require "uuid"

struct UUID
  def self.from_bson(bson : BSON::Field) : self
    case bson
    when String
      UUID.new bson.as(String)
    when BSON::Binary
      UUID.new(bson.as(BSON::Binary).data)
    else
      raise "Unable to convert bson #{bson.class} to UUID"
    end
  end
end
