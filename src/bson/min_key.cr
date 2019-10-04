class BSON
  struct MinKey
    Instance = MinKey.allocate

    def self.new
      Instance
    end
    def to_json(json : JSON::Builder)
        json.object do
            json.field("$minKey",1)
        end
    end

  end
end