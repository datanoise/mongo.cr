def Array.new(bson_value : BSON::Value)
  bson = bson_value.value
  unless bson.is_a?(BSON)
    raise "this bson value is not a bson object - it's #{typeof(bson)}" 
  end

  new(bson)
end

def Array.new(bson : BSON)
  raise "this bson is not an array" unless bson.array?

  array = new

  bson.each do |bson_value|
    array << T.new(bson_value)
  end

  array
end

def Hash.new(bson_value : BSON::Value)
  bson = bson_value.value
  unless bson.is_a?(BSON)
    raise "this bson value is not a bson object - it's #{typeof(bson)}" 
  end

  new(bson)
end

def Hash.new(bson : BSON)
  hash = new

  bson.each_pair do |key, bson_value|
    hash[key] = V.new(bson_value)
  end

  hash
end

{% for type in [Int32, Int64, Bool, Float64, Nil, String, Time, Regex, String] %}
  def {{type}}.new(bson_value : BSON::Value)
    bson_value.value as {{type}}
  end
{% end %}
