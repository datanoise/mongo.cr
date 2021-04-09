require "../src/mongo"
require "spec"

describe Mongo::Client do
  it "should be able to connect to a server" do
    client = Mongo::Client.new(mongo_test_uri)
    client.uri.string.should eq(mongo_test_uri)
    client.max_message_size.should be > 0
    client.max_bson_size.should be > 0
  end

  it "should be able to modify write_concern" do
    client = Mongo::Client.new(mongo_test_uri)
    client.write_concern.fsync.should be_false
    client.write_concern.fsync = true
    client.write_concern.fsync.should be_true
    write_concern = Mongo::WriteConcern.new
    write_concern.journal = true
    client.write_concern = write_concern
    client.write_concern.journal.should be_true
  end

  it "should be able to modify read preferences" do
    client = Mongo::Client.new(mongo_test_uri)
    client.read_prefs.mode.should eq(LibMongoC::ReadMode::PRIMARY)
    tag = BSON.new
    tag["name"] = "my_tag"
    client.read_prefs.add_tag tag
    tag = client.read_prefs.tags["0"]
    fail("expected an array") unless tag.is_a?(BSON)
    tag["name"].should eq("my_tag")

    read_prefs = Mongo::ReadPrefs.new
    read_prefs.mode = LibMongoC::ReadMode::PRIMARY_PREFERRED

    client.read_prefs = read_prefs
    client.read_prefs.mode.should eq(LibMongoC::ReadMode::PRIMARY_PREFERRED)
  end

  it "should read default ssl opts" do
    opts = Mongo.ssl_opt_get_default
    if opts.is_a?(LibMongoC::SSLOpt)
      opts.allow_invalid_hostname.should be_false
    else
      fail("expceted a sslopt object")
    end
  end
end
