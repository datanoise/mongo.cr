class Array(T)
  def to_bson
    return BSON.from_json(self.to_json)
  end
end