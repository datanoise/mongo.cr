def create_collection
  client = Mongo::Client.new("mongodb://localhost")
  db = client["my_db_#{Time.now.to_i}"]
  db["my_col"]
end

def with_collection
  col = create_collection
  begin
    yield col
  ensure
    col.database.drop
  end
end


