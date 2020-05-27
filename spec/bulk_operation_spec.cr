require "../src/mongo"
require "./spec_helper"
require "spec"

describe Mongo::BulkOperation do
  it "should be able to bulk insert documents" do
    with_collection do |col|
      bo = col.create_bulk_operation
      bo.insert({"name" => "Bob"})
      bo.insert({"name" => "Joe"})
      result = bo.execute
      fail "Expected BSON" unless result.is_a?(BSON)
      result["nInserted"].should eq(2)
    end
  end

  it "should be able to bulk update documents" do
    with_collection do |col|
      col.insert({"name" => "Bob"})
      col.insert({"name" => "Joe"})
      col.insert({"name" => "Bill"})

      bo = col.create_bulk_operation

      bo.update({"name" => "Bob"}, {"$set" => {"tag" => "p1"}})
      bo.update({"name" => "Joe"}, {"$set" => {"tag" => "p2"}})
      result = bo.execute

      fail "Expected BSON" unless result.is_a?(BSON)
      result["nModified"].should eq(2)

      bob = col.find_one({"name" => "Bob"})
      fail "Expected BSON" unless bob.is_a?(BSON)
      bob.not_nil!["tag"].should eq("p1")

      joe = col.find_one({"name" => "Joe"})
      fail "Expected BSON" unless joe.is_a?(BSON)
      joe.not_nil!["tag"].should eq("p2")
    end
  end

  it "should be able to bulk remove documents" do
    with_collection do |col|
      col.insert({"name" => "Bob"})
      col.insert({"name" => "Joe"})
      col.insert({"name" => "Bill"})

      bo = col.create_bulk_operation
      bo.remove({"name" => "Bob"})
      bo.remove({"name" => "Joe"})

      result = bo.execute

      fail "Expected BSON" unless result.is_a?(BSON)
      result["nRemoved"].should eq(2)

      col.count.should eq(1)
    end
  end

  it "should be able to bulk replace documents" do
    with_collection do |col|
      col.insert({"name" => "Bob"})
      col.insert({"name" => "Joe"})
      col.insert({"name" => "Bill"})

      bo = col.create_bulk_operation
      bo.replace_one({"name" => "Bob"}, {"title" => "Replaced"})
      bo.replace_one({"name" => "Bill"}, {"title" => "Fired"})
      bo.remove({"name" => "Joe"})

      result = bo.execute

      fail "Expected BSON" unless result.is_a?(BSON)
      result["nModified"].should eq(2)

      col.find_one({"name" => "Bob"}).should be_nil
      col.find_one({"title" => "Replaced"}).should_not be_nil
    end
  end
end
