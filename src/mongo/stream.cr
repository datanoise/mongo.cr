require "socket"

# http://mongoc.org/libmongoc/current/mongoc_client_t.html#streams
module Mongo::Stream
  @@registry = {} of LibMongoC::Stream* => { Socket, String, UInt16, Bool }

  def self.initiator(uri : LibMongoC::Uri, host : LibMongoC::HostList, user_data : Void*, error : LibBSON::BSONError*)
    begin
      # The socket cannot be connected right away, because the code needs to block the event loop.
      # If any async I/O syscall is used to connect then another Fiber could run, cause a deadlock
      # in the meantime and hang the program (libmongoc code is sprinkled with pthread mutexes).
      socket = TCPSocket.new
      stream = LibC.malloc(sizeof(LibMongoC::Stream).to_u32).as(LibMongoC::Stream*)

      stream.value.type = 0
      stream.value.destroy = -> (stream : LibMongoC::Stream*) {
        @@registry.delete(stream)
        LibC.free(stream.as(Void*))
      }
      stream.value.close = -> (stream : LibMongoC::Stream*) {
        io = Stream.get_io(stream)
        io.close() unless io.closed?
        0
      }
      stream.value.flush = -> (stream : LibMongoC::Stream*) {
        io = Stream.get_io(stream)
        io.flush
        0
      }
      stream.value.writev = -> (stream : LibMongoC::Stream*, iov : LibMongoC::IOVec*, iovcnt : LibC::SizeT, timeout_msec : Int32) {
        io = Stream.get_io(stream)
        count = 0_i64
        begin
          iovcnt.times do
            slice = Slice.new(iov.value.ion_base, iov.value.ion_len.to_i32)
            len = slice.bytesize
            io.write(slice)
            if len != iov.value.ion_len && len
              count += len
              break
            end
            count += len ? len : 0
            iov += 1
          end
        rescue
          io.close
        end
        LibC::SSizeT.cast(count)
      }
      stream.value.readv = -> (stream : LibMongoC::Stream*, iov : LibMongoC::IOVec*, iovcnt : LibC::SizeT, min_bytes : LibC::SizeT, timeout : Int32) {
        io = Stream.get_io(stream)
        count = 0_i64
        begin
          iovcnt.times do
            len = iov.value.ion_len.to_i32
            io.read_fully(Slice.new(iov.value.ion_base, len))
            count += len
            iov += 1
          end
        rescue IO::EOFError
        rescue
          io.close
        end
        LibC::SSizeT.cast(count)
      }
      stream.value.setsockopt = -> (stream : LibMongoC::Stream*, level : Int32, optname : Int32, optval : Void*, optlen : Int32) {
        io = Stream.get_io(stream)
        LibC.setsockopt(io.fd, level, optname, optval, optlen)
      }
      stream.value.get_base_stream = Pointer(Void).null
      stream.value.check_closed = -> (stream : LibMongoC::Stream*) {
        io = Stream.get_io(stream)
        io.closed?
      }
      stream.value.poll = ->(stream_poll_array: LibMongoC::StreamPoll*, nstreams: Int32, timeout_msec: Int32) {
        (0...nstreams).each do |index|
          stream_poll = stream_poll_array[index]
          io = Stream.get_io(stream_poll.stream)
          stream_poll.revents = io.try &.closed? ? 0x08 : stream_poll.events
          stream_poll_array[index] = stream_poll
        end
        nstreams
      }
      stream.value.failed = ->(stream : LibMongoC::Stream*) {
        io = Stream.get_io(stream)
        io.close unless io.closed?
        if @@registry.has_key? stream
          @@registry.delete(stream)
          LibC.free(stream.as(Void*))
        end
      }
      stream.value.timed_out = ->(stream : LibMongoC::Stream*) {
        false
      }
      stream.value.should_retry = ->(stream : LibMongoC::Stream*) {
        false
      }

      @@registry[stream] = { socket, String.new(host.value.host.to_slice), host.value.port, false }
      stream
    rescue
      nil
    end
  end

  def self.get_io(stream : LibMongoC::Stream*)
    io, host, port, connected = @@registry[stream]
    unless connected || !io
      io.connect host, port
      @@registry[stream] = {io, host, port, true}
    end
    io
  end
end
