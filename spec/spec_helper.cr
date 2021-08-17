def create_client
  Mongo::Client.new("mongodb://production_user:mylongpassword@cluster0-shard-00-00.zsemy.mongodb.net:27017,cluster0-shard-00-01.zsemy.mongodb.net:27017,cluster0-shard-00-02.zsemy.mongodb.net:27017/core_test?ssl=true&replicaSet=atlas-i7nkdu-shard-0&authSource=admin&retryWrites=true&w=majority")
end

def create_database
  client = create_client
  client["core_test"]
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


