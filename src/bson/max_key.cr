class BSON
  struct MaxKey
    Instance = MaxKey.allocate

    def self.new
      Instance
    end
    def to_json(json : JSON::Builder)
        json.object do
            json.field("$maxKey",1)
        end
    end
  end
end