require "socket"
require "uri"
require "openssl"

module Mongo::Stream::TLSStream
  extend SocketStream
  extend self

  @@registry = {} of LibMongoC::Stream* => { Socket, LibMongoC::Uri, String, UInt16, OpenSSL::SSL::Socket? }

  def self.new(uri : LibMongoC::Uri, host : LibMongoC::HostList, _user_data : Void*, _error : LibBSON::BSONError*)
    # The socket cannot be connected right away, because the code needs to block the event loop.
    # If any async I/O syscall is used to connect then another Fiber could run, cause a deadlock
    # in the meantime and hang the program (libmongoc code is sprinkled with pthread mutexes).
    socket = TCPSocket.new
    handle = LibC.malloc(sizeof(LibMongoC::Stream).to_u32).as(LibMongoC::Stream*)
    handle.value.type = 1 # Socket stream
    handle.value.destroy = -> self.destroy(LibMongoC::Stream*)
    handle.value.close = -> self.close(LibMongoC::Stream*)
    handle.value.flush = -> self.flush(LibMongoC::Stream*)
    handle.value.writev = -> self.writev(LibMongoC::Stream*, LibMongoC::IOVec*, LibC::SizeT, Int32)
    handle.value.readv = -> self.readv(LibMongoC::Stream*, LibMongoC::IOVec*, LibC::SizeT, LibC::SizeT, Int32)
    handle.value.setsockopt = -> self.setsockopt(LibMongoC::Stream*, Int32, Int32, Void*, Int32)
    handle.value.check_closed = -> self.check_closed(LibMongoC::Stream*)
    handle.value.poll = -> self.poll(LibMongoC::StreamPoll*, Int32, Int32)
    handle.value.failed = -> self.failed(LibMongoC::Stream*)
    handle.value.timed_out = -> self.timed_out(LibMongoC::Stream*)
    handle.value.should_retry = -> self.should_retry(LibMongoC::Stream*)
    handle.value.get_base_stream = Pointer(Void).null
    @@registry[handle] = {
      socket,
      uri,
      String.new(host.value.host.to_slice),
      host.value.port,
      nil
    }
    handle
    rescue
      nil
  end

  def get_io(stream : LibMongoC::Stream*)
    io, uri, host, port, ssl_socket = @@registry[stream]
    unless ssl_socket
      io.connect host, port
      context = OpenSSL::SSL::Context::Client.new
      uri_obj = URI.parse String.new(LibMongoC.uri_get_string uri)
      options = uri_obj.query_params
      # Following the libmongoc openssl context configuration:
      # https://github.com/mongodb/mongo-c-driver/blob/272df14b7be4bd6000045cdf0a56f76855faff80/src/libmongoc/src/mongoc/mongoc-openssl.c#L464
      # And the uri parsing & naming for options:
      # https://github.com/mongodb/mongo-c-driver/blob/3f3928c1a739b46ebaaa13df62b37c0348fd6a91/src/libmongoc/src/mongoc/mongoc-ssl.c#L97
      options["tlscafile"]? && context.ca_certificates = options["tlscafile"].as(String)
      if options["tlsinsecure"]? || options["tlsallowinvalidcertificates"]?
        context.verify_mode = OpenSSL::SSL::VerifyMode::NONE
      end
      context.add_options(OpenSSL::SSL::Options::ALL)
      context.add_options(OpenSSL::SSL::Options.flags(
        NO_SSL_V2,
        NO_COMPRESSION,
        NO_SESSION_RESUMPTION_ON_RENEGOTIATION
      ))
      ssl_socket = OpenSSL::SSL::Socket::Client.new(io, context, sync_close: true)
      @@registry[stream] = {io, uri, host, port, ssl_socket}
    end
    ssl_socket.not_nil!
  end
end