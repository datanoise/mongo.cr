require "../src/mongo"
require "./spec_helper"
require "spec"

describe Mongo::GridFS do
  it "should be able to create a new file" do
    with_database do |db|
      fs = db.gridfs

      file = fs.create_file("readme.txt")
      file.save.should be_true
      a_file = fs.find_by_name(file.name)
      fail "cannot find a file" unless a_file
      a_file.name.should eq(file.name)

      file_list = fs.find
      file_list.find{|f| f.name == file.name}.should_not be_nil
    end
  end

  it "should be able to read/write to a file" do
    with_database do |db|
      fs = db.gridfs

      file = fs.create_file("readme.txt")
      file.length.should eq(0)

      file.write("once upon a time".to_slice)
      file.save
      file.length.should eq(16)
      file.tell.should eq(16)

      # we have to look up the file again because mongo-c seek function is buggy
      file = fs.find_by_name(file.name)
      fail "cannot find a file" unless file
      data = file.gets_to_end
      data.should eq("once upon a time")
    end
  end

  it "should be able to delete a file" do
    with_database do |db|
      fs = db.gridfs

      file = fs.create_file("readme.txt")
      file.save.should be_true

      file.remove.should be_true
      fs.find.size.should eq(0)
    end
  end

  it "should be able to drop gridfs" do
    with_database do |db|
      fs = db.gridfs

      file = fs.create_file("readme.txt")
      file.save

      fs.drop

      file = fs.find_by_name("readme.txt")
      file.should be_nil
    end
  end
end
