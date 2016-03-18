class Mongo::IndexOpt
  property background
  property unique
  property name
  property drop_dups
  property sparse
  property expire_after_seconds
  property weights
  property default_language
  property language_override

  def initialize(@background = false, @unique = false, @name = nil,
                 @drop_dups = false, @sparse = false, @expire_after_seconds = 0,
                 @weights = nil, @default_language = nil, @language_override = nil)
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
    @opt.expire_after_seconds = @expire_after_seconds.to_i32
    if weights = @weights
      @opt.weights = weights.to_unsafe
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
