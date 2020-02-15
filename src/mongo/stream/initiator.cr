require "socket"
require "./socket_stream"
require "./tls_stream"

module Mongo::Stream::Initiator
  def self.initiator(uri : LibMongoC::Uri, host : LibMongoC::HostList, user_data : Void*, error : LibBSON::BSONError*)
    if LibMongoC.uri_get_ssl(uri)
      TLSStream.new(uri, host, user_data, error)
    else
      SocketStream.new(uri, host, user_data, error)
    end
  rescue
    nil
  end
end
