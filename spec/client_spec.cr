require "../mongo"
require "spec"

describe Mongo::Client do
  it "should be able to connect to a server" do
    client = Mongo::Client.new("mongodb://localhost")
    client.uri.string.should eq("mongodb://localhost")
    client.max_message_size.should be > 0
    client.max_bson_size.should be > 0
  end

  it "should be able to modify write_concern" do
    client = Mongo::Client.new("mongodb://localhost")
    client.write_concern.fsync.should be_false
    client.write_concern.fsync = true
    client.write_concern.fsync.should be_true
    write_concern = Mongo::WriteConcern.new
    write_concern.journal = true
    client.write_concern = write_concern
    client.write_concern.journal.should be_true
  end

  it "should be able to modify read preferences" do
    client = Mongo::Client.new("mongodb://localhost")
    client.read_prefs.mode.should eq(LibMongoC::ReadMode::READ_PRIMARY)
    tag = BSON.new
    tag["name"] = "my_tag"
    client.read_prefs.add_tag tag
    tag = client.read_prefs.tags["0"]
    fail("expected an array") unless tag.is_a?(BSON)
    tag["name"].should eq("my_tag")

    read_prefs = Mongo::ReadPrefs.new
    read_prefs.mode = LibMongoC::ReadMode::READ_PRIMARY_PREFERRED

    client.read_prefs = read_prefs
    client.read_prefs.mode.should eq(LibMongoC::ReadMode::READ_PRIMARY_PREFERRED)
  end
end

