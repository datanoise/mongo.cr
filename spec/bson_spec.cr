require "../src/bson"
require "spec"

macro expect_value(v)
  %v = {{v}}
  if %v.is_a?(BSON::Value)
    %v.value
  else
    fail "expected a value but got #{{{v}}}"
  end
end

describe BSON::ObjectId do
  it "should be able to create a new ObjectId" do
    oid = BSON::ObjectId.new
    oid.should_not be_nil
  end

  it "should be able to create ObjectId from a string" do
    oid = BSON::ObjectId.new
    str = oid.to_s
    other = BSON::ObjectId.new(str)
    oid.should eq(other)
  end

  it "should be able to calculate an ObjectId hash" do
    oid = BSON::ObjectId.new
    oid.hash.should be > 0
  end

  it "should be able to get a time" do
    oid = BSON::ObjectId.new
    (oid.time - Time.utc_now).should be < 1.seconds
  end

  it "should be able to compare ObjectIds" do
    oid1 = BSON::ObjectId.new
    oid2 = BSON::ObjectId.new
    oid1.should be < oid2
  end
end


describe BSON::Timestamp do
  it "should be comparable" do
    t = Time.now
    t1 = BSON::Timestamp.new(t.to_unix, 1)
    t2 = BSON::Timestamp.new(t.to_unix, 2)
    t2.should be > t1
  end
end

describe BSON do
  it "should be able to create an empty bson" do
    bson = BSON.new
    bson.count.should eq(0)
  end

  it "should be able to append Int32" do
    bson = BSON.new
    bson["int_val"] = 1
    bson.count.should eq(1)
    bson.has_key?("int_val").should be_true
    expect_value(bson.each.next).should eq(1)
  end

  it "should be able to append binary" do
    bson = BSON.new
    bson["bin"] = BSON::Binary.new(BSON::Binary::SubType::Binary, "binary".to_slice)
    bson.count.should eq(1)
    bson.has_key?("bin").should be_true
  end

  it "should be able to append boolean" do
    bson = BSON.new
    bson["bool"] = true
    bson.count.should eq(1)
    bson.has_key?("bool")
  end

  it "should be able to append float" do
    bson = BSON.new
    bson["double"] = 1.0
    expect_value(bson.each.next).should eq(1.0)
  end

  it "should be able to append Int64" do
    bson = BSON.new
    bson["int64"] = 1_i64
    expect_value(bson.each.next).should eq(1_i64)
  end

  it "should be able to append min key" do
    bson = BSON.new
    bson["min"] = BSON::MinKey.new
    expect_value(bson.each.next).should eq(BSON::MinKey.new)
  end

  it "should be able to append max key" do
    bson = BSON.new
    bson["min"] = BSON::MaxKey.new
    expect_value(bson.each.next).should eq(BSON::MaxKey.new)
  end

  it "should be able to append nil" do
    bson = BSON.new
    bson["min"] = nil
    expect_value(bson.each.next).should be_nil
  end

  it "should be able to append ObjectId" do
    bson = BSON.new
    oid = BSON::ObjectId.new
    bson["oid"] = oid
    expect_value(bson.each.next).should eq(oid)
  end

  it "should be able to append string" do
    bson = BSON.new
    bson["en"] = "hello"
    bson["ru"] = "привет"
    bson["en"].should eq("hello")
    bson["ru"].should eq("привет")
  end

  it "should be able to append document" do
    bson = BSON.new
    bson["v"] = 1
    bson.append_document("doc") do |child|
      child["body"] = "document body"
    end

    doc = bson["doc"]
    if doc.is_a?(BSON)
      doc.has_key?("body").should be_true
      doc["body"].should eq("document body")
    else
      fail "doc must be BSON object"
    end
  end

  it "should invalidate child document after append" do
    bson = BSON.new
    bson["v"] = 1
    child = nil
    bson.append_document("doc") do |child|
      child.not_nil!["body"] = "document body"
    end
    expect_raises(Exception) do
      child.not_nil!["v"] = 2
    end
  end

  it "should be able to append an array" do
    bson = BSON.new
    bson["v"] = 1
    bson.append_array("ary") do |child|
      child << "a1"
      child << "a2"
      child << nil
      child << 1
    end

    ary = bson["ary"]
    if ary.is_a?(BSON)
      ary.count.should eq(4)
      ary["0"].should eq("a1")
      ary["2"].should be_nil
      ary["3"].should eq(1)
    else
      fail "ary must be BSON object"
    end
  end

  it "should be able to append symbol" do
    bson = BSON.new
    bson["s"] = BSON::Symbol.new("symbol")
    sym = bson["s"]
    if sym.is_a?(BSON::Symbol)
      sym.name.should eq("symbol")
    else
      fail "sym must be BSON::Symbol"
    end
  end

  it "should be able to append time" do
    t = Time.now
    bson = BSON.new
    bson["time"] = t
    bson_t = bson["time"]
    if bson_t.is_a?(Time)
      bson_t.to_unix.should eq(t.to_utc.to_unix)
    else
      fail "expected Time"
    end
  end

  it "should be able to append timestamp" do
    t = Time.now
    bson = BSON.new
    bson["ts"] = BSON::Timestamp.new(t.to_unix, 1)
    bson["ts"].should eq(BSON::Timestamp.new(t.to_unix, 1))
  end

  it "should be able to append regex" do
    bson = BSON.new
    re = /blah/im
    bson["re"] = re
    val = bson["re"]
    if val.is_a?(Regex)
      val.source.should eq(re.source)
      val.options.should eq(re.options)
    else
      fail "expected regex value"
    end
  end

  it "should be able to append code" do
    bson = BSON.new
    code = BSON::Code.new("function() { return 'OK'; }")
    bson["code"] = code
    bson["code"].should eq(code)
  end

  it "should be able to append code with scope" do
    bson = BSON.new

    scope = BSON.new
    scope["x"] = 42
    code = BSON::Code.new("function() { return x; }", scope)

    bson["code"] = code
    bson["code"].should eq(code)
  end

  it "should be able to append document" do
    bson = BSON.new
    child = BSON.new
    child["x"] = 42
    bson["doc"] = child
    bson["doc"].should eq(child)
  end

  it "should be able to concat document" do
    bson = BSON.new
    child = BSON.new
    child["x"] = 42
    bson["y"] = "y"
    bson.concat child
    bson["x"].should eq(child["x"])
  end

  it "should be comparable" do
    bson1 = BSON.new
    bson1["x"] = 1
    bson2 = BSON.new
    bson2["x"] = 2
    bson2.should be > bson1
  end

  it "should be able to iterate" do
    bson = BSON.new
    bson["bool"] = true
    bson["int"] = 1
    iter = bson.each
    expect_value(iter.next).should be_true
    expect_value(iter.next).should eq(1)
  end

  it "should be able to iterate pairs" do
    bson = BSON.new
    bson["bool"] = false
    bson["int"] = 1
    v = [{"bool", false}, {"int", 1}]
    count = 0
    bson.each_pair do |key, val|
      v[count][0].should eq(key)
      v[count][1].should eq(val.value)
      count += 1
    end
  end

  it "should be able to clear content" do
    bson = BSON.new
    bson["x"] = "string"
    bson.count.should eq(1)
    bson.clear
    bson.empty?.should be_true
  end

  it "should be able to clone BSON" do
    bson = BSON.new
    bson["x"] = 42
    bson["body"] = "content"

    copy = bson.clone
    copy.should eq(bson)
  end

  it "should be able to convert Hash to BSON" do
    query = [{"$match" => {"status" => "A"}},
             {"$group" => {"_id" => "$cust_id", "total" => {"$sum" => "$amount"}}}]
    bson_query = query.to_bson
    elem1 = bson_query["0"]
    fail "expected BSON" unless elem1.is_a?(BSON)
    match = elem1["$match"]
    fail "expected BSON" unless match.is_a?(BSON)
    match["status"].should eq("A")
  end

  it "should be able to detect array type" do
    ary = ["a", "b", "c"]
    ary.to_bson.array?.should be_true
  end

  it "should be able to decode bson" do
    bson = BSON.new
    bson["x"] = 42
    bson.append_array("ary") do |child|
      child << 1
      child << 2
      child << 3
    end
    bson.append_document("doc") do |child|
      child["y"] = "text"
    end
    h = {"x" => 42, "ary" => [1,2,3], "doc" => {"y" => "text"}}
    bson.decode.should eq(h)
  end

  it "should be able to encode to bson" do
    h = {"x" => 42, "ary" => [1,2,3], "doc" => {"y" => "text"}}
    bson = h.to_bson
    bson["x"].should eq(42)
    ary = bson["ary"]
    fail "expected BSON" unless ary.is_a?(BSON)
    ary["0"].should eq(1)
  end

  it "should decode json" do
    s = "{ \"sval\" : \"1234\", \"ival\" : 1234 }"
    bson = BSON.from_json s
    bson.to_s.should eq s
  end

  it "should error json" do
    s = "{ this = wrong }"
    expect_raises(Exception) do
      bson = BSON.from_json s
    end
  end
end
