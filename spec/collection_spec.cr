require "../src/mongo"
require "./spec_helper"
require "spec"

describe Mongo::Collection do
  it "should be able to perform aggregation" do
    with_collection do |col|
      doc1 = {"cust_id" => "A123", "amount" => 500, "status" => "A"}.to_bson
      col.insert doc1
      doc2 = {"cust_id" => "A123", "amount" => 250, "status" => "A"}.to_bson
      col.insert doc2
      doc3 = {"cust_id" => "B212", "amount" => 200, "status" => "A"}.to_bson
      col.insert doc3
      doc4 = {"cust_id" => "A123", "amount" => 300, "status" => "D"}.to_bson
      col.insert doc4
      col.count.should eq(4)

      pipeline = [{"$match" => {"status" => "A"}},
                  {"$group" => {"_id" => "$cust_id", "total" => {"$sum" => "$amount"}}}].to_bson
      cur = col.aggregate(pipeline)
      cur.to_a.to_s.should eq("[{ \"_id\" : \"B212\", \"total\" : 200 }, { \"_id\" : \"A123\", \"total\" : 750 }]")
    end
  end

  it "should be able to drop a collection" do
    with_collection do |col|
      col.insert({"name" => "Bob"})
      col.database.try &.collection_names.includes?(col.name).should be_true
      col.drop
      col.database.try &.collection_names.includes?(col.name).should be_false
    end
  end

  it "should be able to insert, find and delete documents" do
    with_collection do |col|
      col.insert({"name" => "Bob", "age" => 23})
      cursor = col.find({"name" => "Bob"})
      doc = cursor.next
      fail "inspected a document" unless doc.is_a?(BSON)
      doc["name"].should eq("Bob")
      doc["age"].should eq(23)
      cursor.more.should be_true
      cursor.next.should be_nil
      # cursor.more.should be_false
      col.remove({"name" => "Bob"})
      col.count.should eq(0)
    end
  end

  it "should be able to create a new index" do
    with_collection do |col|
      opt = Mongo::IndexOpt.new(name: "my_index")
      col.create_index({"name" => 1}, opt)
      cur = col.find_indexes

      index = cur.next
      fail "expected BSON" unless index.is_a?(BSON)
      index["name"].should eq("_id_")

      index = cur.next
      fail "expected BSON" unless index.is_a?(BSON)
      index["name"].should eq("my_index")

      col.drop_index("my_index")

      col.find_indexes.to_a.size.should eq(1)
    end
  end

  it "should be able to insert in bulk" do
    with_collection do |col|

      docs = [{"name" => "Bob"}, {"name" => "Joe"}, {"name" => "Steve"}]
      col.insert_bulk docs

      col.count.should eq(3)

    end
  end

  it "should be able to modify write_concern" do
    with_collection do |col|
      col.write_concern.fsync.should be_false
      col.write_concern.fsync = true
      col.write_concern.fsync.should be_true
      write_concern = Mongo::WriteConcern.new
      write_concern.journal = true
      col.write_concern = write_concern
      col.write_concern.journal.should be_true
    end
  end

  it "should be able to modify read preferences" do
    with_collection do |col|
      col.read_prefs.mode.should eq(LibMongoC::ReadMode::PRIMARY)
      tag = BSON.new
      tag["name"] = "my_tag"
      col.read_prefs.add_tag tag
      tag = col.read_prefs.tags["0"]
      fail("expected an array") unless tag.is_a?(BSON)
      tag["name"].should eq("my_tag")

      read_prefs = Mongo::ReadPrefs.new
      read_prefs.mode = LibMongoC::ReadMode::PRIMARY_PREFERRED

      col.read_prefs = read_prefs
      col.read_prefs.mode.should eq(LibMongoC::ReadMode::PRIMARY_PREFERRED)
    end
  end

  it "should be able to find_and_modify" do
    with_collection do |col|
      col.insert({"name" => "counter", "val" => 0})
      doc = col.find_and_modify({"name" => "counter"}, {"$inc" => {"val" => 1}}).not_nil!
      doc["val"].should eq(0)
      doc = col.find_and_modify({"name" => "counter"}, {"$inc" => {"val" => 1}}).not_nil!
      doc["val"].should eq(1)

      doc = col.find_and_modify({"name" => "counter1"}, {"$inc" => {"val" => 1}})
      doc.should be_nil
    end
  end

  it "should be able to save document" do
    with_collection do |col|
      col.insert({"name" => "counter", "val" => 1})
      doc = col.find({"name" => "counter"}).next
      fail "expected BSON" unless doc.is_a?(BSON)
      obj = doc.decode
      fail "expeced Hash" unless obj.is_a?(Hash)
      obj["val"] = 42
      obj["type"] = "person"
      col.save(obj)

      doc = col.find({"name" => "counter"}).next
      fail "expected BSON" unless doc.is_a?(BSON)
      doc["val"].should eq(42)
      doc["type"].should eq("person")
    end
  end

  it "should be able to rename a collection" do
    with_collection do |col|
      col.insert({"name" => "Bob"})
      col.rename(col.database.try &.name || "", "new_name")
      col.name.should eq("new_name")
    end
  end
end
