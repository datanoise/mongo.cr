require "../bson"

class Mongo::IndexOpt
  property background : Bool
  property unique : Bool
  property name : String?
  property drop_dups : Bool
  property sparse : Bool
  property expire_after_seconds : Int32?
  property weights : BSON?
  property default_language : String?
  property language_override : String?
  property partial_filter_expression : BSON?
  property collation : BSON?

  def initialize(@background = false, @unique = false, @name = nil,
                 @drop_dups = false, @sparse = false, @expire_after_seconds = nil,
                 @weights = nil, @default_language = nil, @language_override = nil,
                 @partial_filter_expression = nil, @collation = nil)
    @opt = LibMongoC::IndexOpt.new
    LibMongoC.index_opt_init(pointerof(@opt))
  end

  def to_unsafe
    @opt.background = @background
    @opt.unique = @unique
    if name = @name
      @opt.name = name.to_unsafe
    end
    @opt.drop_dups = @drop_dups
    @opt.sparse = @sparse

    unless @expire_after_seconds.nil?
      @opt.expire_after_seconds = @expire_after_seconds.not_nil!.to_i32
    end

    if weights = @weights
      @opt.weights = weights.to_unsafe
    end

    if partial = @partial_filter_expression
      @opt.partial_filter_expression = partial.to_unsafe
    end

    if collation = @collation
      @opt.collation = collation.to_unsafe
    end

    if default_language = @default_language
      @opt.default_language = default_language.to_unsafe
    end
    if language_override = @language_override
      @opt.language_override = language_override.to_unsafe
    end

    pointerof(@opt)
  end
end
