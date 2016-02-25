def create_client
  Mongo::Client.new("mongodb://localhost")
end

def create_database
  client = create_client
  client["my_db_#{Time.now.epoch}"]
end

def create_collection
  db = create_database
  db["my_col"]
end

def with_database
  db = create_database
  begin
    yield db
  ensure
    db.drop
  end
end

def with_collection
  with_database do |db|
    col = db["my_col"]
    yield col
  end
end

module TestConverter
  extend self

  def to_bson(bson_value, appender)
    appender << "#{bson_value} - TEST"
  end

  def from_bson(bson_value)
    bson_value.value as String
  end
end

class OtherTestMapping
  BSON.mapping({
    foobar: { type: String, converter: TestConverter }
  })

  def initialize(@foobar : String)
  end
end

class TestMapping
  BSON.mapping({
    foo: String,
    bar: OtherTestMapping,
    baz: { type: Int32, default: 0 }
  })

  def initialize(@foo, @bar, @baz = 0)
  end
end
