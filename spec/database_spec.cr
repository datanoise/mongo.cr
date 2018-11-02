require "../src/mongo"
require "spec"

describe Mongo::Database do
  it "should be able to create a new database" do
    client = Mongo::Client.new("mongodb://localhost")
    db_name = "my_db_#{Time.now.to_unix}"
    db = client[db_name]
    db.name.should eq(db_name)
  end

  it "should be able to creata a collection" do
    client = Mongo::Client.new("mongodb://localhost")
    db = client["my_db_#{Time.now.to_unix}"]
    db.create_collection("my_col")

    db.has_collection?("my_col").should be_true

    col = db.find_collections.find {|col| col["name"] == "my_col"}
    col.should_not be_nil

    db.collection_names.includes?("my_col").should be_true

    db.drop
  end

  it "should be able to manage users" do
    client = Mongo::Client.new("mongodb://localhost")
    db = client["my_db_#{Time.now.to_unix}"]
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

  it "should be able to modify write_concern" do
    client = Mongo::Client.new("mongodb://localhost")
    db = client["my_db_#{Time.now.to_unix}"]
    db.write_concern.fsync.should be_false
    db.write_concern.fsync = true
    db.write_concern.fsync.should be_true
    write_concern = Mongo::WriteConcern.new
    write_concern.journal = true
    db.write_concern = write_concern
    db.write_concern.journal.should be_true
  end

  it "should be able to modify read preferences" do
    client = Mongo::Client.new("mongodb://localhost")
    db = client["my_db_#{Time.now.to_unix}"]
    db.read_prefs.mode.should eq(LibMongoC::ReadMode::PRIMARY)
    tag = BSON.new
    tag["name"] = "my_tag"
    db.read_prefs.add_tag tag
    tag = db.read_prefs.tags["0"]
    fail("expected an array") unless tag.is_a?(BSON)
    tag["name"].should eq("my_tag")

    read_prefs = Mongo::ReadPrefs.new
    read_prefs.mode = LibMongoC::ReadMode::PRIMARY_PREFERRED

    db.read_prefs = read_prefs
    db.read_prefs.mode.should eq(LibMongoC::ReadMode::PRIMARY_PREFERRED)
  end
end
