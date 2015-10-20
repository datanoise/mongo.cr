class BSON
  struct Binary
    enum SubType
      Binary
      Function
      UUID
      MD5
      User
    end

    property! subtype
    property! data

    def initialize(@subtype : SubType, @data : Slice(UInt8))
    end

    def to_raw_type
      case @subtype
      when SubType::Binary
        LibBSON::SubType::BSON_SUBTYPE_BINARY
      when SubType::Function
        LibBSON::SubType::BSON_SUBTYPE_FUNCTION
      when SubType::UUID
        LibBSON::SubType::BSON_SUBTYPE_UUID
      when SubType::MD5
        LibBSON::SubType::BSON_SUBTYPE_MD5
      when SubType::User
        LibBSON::SubType::BSON_SUBTYPE_USER
      else
        raise "unable to handle subtype #{@subtype}"
      end
    end
  end
end
