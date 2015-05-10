class BSON
  class BSONError < Exception
    getter domain, code, detail

    def initialize(bson_error)
      @domain = bson_error.value.domain
      @code = bson_error.value.code
      @detail = String.new bson_error.value.message.to_unsafe
      super("Domain: #{@domain}, code: #{@code}, #{@detail}")
    end
  end
end