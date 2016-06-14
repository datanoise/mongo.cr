class BSON
  class BSONError < Exception
    getter domain, code, detail
  	@domain : UInt32
  	@code : UInt32
  	@detail : String

    def initialize(bson_error)
      @domain = bson_error.value.domain
      @code = bson_error.value.code
      @detail = String.new bson_error.value.message.to_unsafe
      super("Domain: #{@domain}, code: #{@code}, #{@detail}")
    end
  end
end
