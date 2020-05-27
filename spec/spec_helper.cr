def mongo_test_uri
  URI.new(
    scheme: "mongodb",
    host: ENV["MONGODB_HOST"]? || "localhost",
    port: (ENV["MONGODB_PORT"]? || 27017).to_i,
    user: ENV["MONGODB_USER"]? || "root",
    password: ENV["MONGODB_PASS"]? || ""
  ).to_s
end

def create_client
  client = Mongo::Client.new(mongo_test_uri)
  client.setup_stream
  client
end

def create_database
  client = create_client
  client["my_db_#{Time.utc.to_unix_ms}"]
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
