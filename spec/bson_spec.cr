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
    t1 = BSON::Timestamp.new(t.ticks, 1)
    t2 = BSON::Timestamp.new(t.ticks, 2)
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
      bson_t.epoch.should eq(t.to_utc.epoch)
    else
      fail "expected Time"
    end
  end

  it "should be able to append timestamp" do
    t = Time.now
    bson = BSON.new
    bson["ts"] = BSON::Timestamp.new(t.ticks, 1)
    bson["ts"].should eq(BSON::Timestamp.new(t.ticks, 1))
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
    bson = BSON.build do |doc|
      doc.field("x", 42)
      doc.field("ary") do |appender|
        appender.array do |array|
          array << 1
          array << 2
          array << 3
        end
      end
      doc.field("doc") do |appender|
        appender.document do |doc|
          doc.field("y", "text")
        end
      end
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

  context "build" do
    it "yields a BSON::Builder" do
      BSON.build do |builder|
        builder.should be_a(BSON::Builder)
      end
    end

    it "returns a bson" do
      BSON.build {}.should be_a(BSON)
    end

    it "is able to add fields" do
      bson = BSON.build do |doc|
        doc.field("foo", "bar")
        doc.field(:bar, "baz")
        doc.field(1, "foobar")
      end

      bson["foo"].should eq("bar")
      bson["bar"].should eq("baz")
      bson["1"].should eq("foobar")
    end

    it "should be able to append document" do
      bson = BSON.build do |doc|
        doc.field("doc") do |appender|
          appender.document do |child|
            child.field("body", "document body")
          end
        end
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
      child_doc = nil
      bson = BSON.build do |doc|
        doc.field("doc") do |appender|
          appender.document do |child|
            child_doc = child.bson
            child.field("body", "document body")
          end
        end
      end

      expect_raises do
        child_doc.not_nil!["v"] = 2
      end
    end

    it "should be able to append an array" do
      bson = BSON.build do |doc|
        doc.field("ary") do |appender|
          appender.array do |array|
            array << "a1"
            array << "a2"
            array << nil
            array << 1
          end
        end
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
  end

  context "from bson" do
    it "creates an array from a bson array" do
      bson = BSON.build_array do |doc|
        doc << "foo"
        doc << "bar"
        doc << "baz"
      end

      Array(String).new(bson).should eq(%w(foo bar baz))
    end

    it "creates a hash from a bson document" do
      bson = BSON.build do |doc|
        doc.field(:foo, "bar")
        doc.field(:bar, "baz")
      end

      Hash(String, String).new(bson).should eq({ "foo": "bar", "bar": "baz" })
    end
  end

  context "mapping" do
    it "produces a bson with all specified attributes" do
      mapping = TestMapping.new("bar", OtherTestMapping.new("foo"))
      bson = mapping.to_bson
      bson["foo"].should eq("bar")
      bson["baz"].should eq(0)
      bar = bson["bar"]
      if bar.is_a?(BSON)
        bar["foobar"].should eq("foo - TEST")
      else
        fail "bar must be a BSON object"
      end
    end

    it "maps all attributes from a bson" do
      bson = BSON.build do |doc|
        doc.field :foo, "bar"
        doc.field :bar do |appender|
          appender.document do |doc|
            doc.field :foobar, "foo"
          end
        end
      end

      mapping = TestMapping.new(bson)
      mapping.foo.should eq("bar")
      mapping.bar.foobar.should eq("foo")
      mapping.baz.should eq(0)
    end
  end
end
