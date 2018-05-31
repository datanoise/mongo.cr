require "../src/mongo/uri"
require "spec"

describe Mongo::Uri do
  it "should be able to create new uri" do
    uri = Mongo::Uri.new "mongodb://localhost:27017"
    uri.hosts.size.should eq(1)
    host = uri.hosts.first
    host.host.should eq("localhost")
    host.port.should eq(27017)
  end

  it "should work with various ports" do
    uri = Mongo::Uri.new "mongodb://localhost:1443"
    uri.hosts.size.should eq(1)
    host = uri.hosts.first
    host.host.should eq("localhost")
    host.port.should eq(1443)
  end

  it "should be able to create new uri with host and port" do
    uri = Mongo::Uri.new "localhost", 27017
    uri.hosts.size.should eq(1)
    host = uri.hosts.first
    host.host.should eq("localhost")
    host.port.should eq(27017)
  end

  it "should be able to parse options" do
    uri = Mongo::Uri.new "mongodb://localhost/?safe=true&journal=false"
    uri.options["journal"].should be_false
    uri.options["safe"].should be_true
  end

  it "should be able to parse auth_source and auth_mechanism" do
    uri = Mongo::Uri.new "mongodb://christian:secret@domain.com:27017/?authMechanism=GSSAPI"
    uri.auth_mechanism.should eq("GSSAPI")
    uri.auth_source.should eq("$external")
    uri.username.should eq("christian")
    uri.password.should eq("secret")
  end

  it "should be able to parse mechanism_properties" do
    uri = Mongo::Uri.new "mongodb://user%40DOMAIN.COM:password@localhost/?authMechanism=GSSAPI&authMechanismProperties=SERVICE_NAME:other,CANONICALIZE_HOST_NAME:true"
    uri.mechanism_properties["SERVICE_NAME"].should eq("other")
    uri.mechanism_properties["CANONICALIZE_HOST_NAME"].should eq("true")
  end

  it "should be able to recognize ssl" do
    uri = Mongo::Uri.new "mongodb://localhost/?ssl=true"
    uri.ssl.should be_true
  end

  it "should be able to parse write concerns" do
    uri = Mongo::Uri.new "mongodb://localhost/?w=2&journal=true"
    uri.write_concern.w.should eq(2)
    uri.write_concern.journal.should eq(true)
  end

  it "should be able to parse database" do
    uri = Mongo::Uri.new "mongodb://localhost/db"
    uri.database.should eq("db")
  end

  it "should be able to parse replica set" do
    uri = Mongo::Uri.new "mongodb://db1.example.net,db2.example.net:2500/?replicaSet=test&connectTimeoutMS=300000"
    uri.replica_set.should eq("test")
    uri.hosts.size.should eq(2)
  end
end
