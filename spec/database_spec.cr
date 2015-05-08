require "../mongo"
require "spec"

describe Mongo::Database do
  it "should be able to create a new database" do
    client = Mongo::Client.new("mongodb://localhost")
    db_name = "my_db_#{Time.now.to_i}"
    db = client[db_name]
    db.name.should eq(db_name)
  end

  it "should be able to manage users" do
    client = Mongo::Client.new("mongodb://localhost")
    # db = client["my_db_#{Time.now.to_i}"]
    db = client["my_db"]
    db.add_user("new_user", "new_pass")
    db["my_col"].insert(BSON.new)
    user = db.users.not_nil!["0"]
    if user.is_a?(BSON)
      user["user"].should eq("new_user")
    else
      fail "expected a document"
    end
    db.remove_user("new_user")
    db.users.not_nil!.empty?.should be_true
    db.drop
  end
end
