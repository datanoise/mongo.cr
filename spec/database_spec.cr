require "../src/mongo"
require "spec"

DB_STRING="mongodb://core:core@ds015740.mlab.com:15740/core_test"

describe Mongo::Database do
  it "should be able to create a new database" do
    client = Mongo::Client.new(DB_STRING)
    db_name = "core_test"
    db = client[db_name]
    db.name.should eq(db_name)
  end

  it "should be able to creata a collection" do
    client = Mongo::Client.new(DB_STRING)
    db = client["core_test"]
    db.create_collection("my_col")

    db.has_collection?("my_col").should be_true

    col = db.find_collections.find {|col| col["name"] == "my_col"}
    col.should_not be_nil

    db.collection_names.includes?("my_col").should be_true
    db["my_col"].drop
  end

  it "should be able to manage users" do
    fail "Current test service and client do not use TLS and the driver warns not to add user without tls"
    #client = Mongo::Client.new(DB_STRING)
    #db = client["core_test"]
    #db.add_user("new_user", "new_pass")
    #user = db.users.not_nil!["0"]
    #if user.is_a?(BSON)
    #  user["user"].should eq("new_user")
    #else
    #  fail "expected a document"
    #end
    #db.remove_user("new_user")
    #db.users.not_nil!.empty?.should be_true
    #db.drop
  end

  it "should be able to modify write_concern" do
    client = Mongo::Client.new(DB_STRING)
    db = client["core_test"]
    db.write_concern.fsync.should be_false
    db.write_concern.fsync = true
    db.write_concern.fsync.should be_true
    write_concern = Mongo::WriteConcern.new
    write_concern.journal = true
    db.write_concern = write_concern
    db.write_concern.journal.should be_true
  end

  it "should be able to modify read preferences" do
    client = Mongo::Client.new(DB_STRING)
    db = client["core_test"]
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
