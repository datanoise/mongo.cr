require "socket"

module Mongo::Stream::SocketStream
  extend self

  @@registry = {} of LibMongoC::Stream* => { Socket, String, UInt16, Bool }

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
    @@registry[handle] = { socket, String.new(host.value.host.to_slice), host.value.port, false }
    handle
  end

  def destroy(stream : LibMongoC::Stream*)
    @@registry.delete(stream)
    LibC.free(stream.as(Void*))
  end

  def close(stream : LibMongoC::Stream*)
    io = self.get_io(stream)
    io.close() unless io.closed?
    0
  end

  def flush(stream : LibMongoC::Stream*)
    io = self.get_io(stream)
    io.flush
    0
  end

  def writev(stream : LibMongoC::Stream*, iov : LibMongoC::IOVec*, iovcnt : LibC::SizeT, _timeout_msec : Int32)
    io = self.get_io(stream)
    count : LibC::SSizeT = 0
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
      io.flush
    rescue
      io.close
    end
    count
  end

  def readv(stream : LibMongoC::Stream*, iov : LibMongoC::IOVec*, iovcnt : LibC::SizeT, _min_bytes : LibC::SizeT, _timeout : Int32)
    io = self.get_io(stream)
    count : LibC::SSizeT = 0
    begin
      iovcnt.times do
        len = iov.value.ion_len.to_i32
        io.read_fully(Slice.new(iov.value.ion_base, len))
        count += len
        iov += 1
      end
      io.flush
    rescue IO::EOFError
    rescue
      io.close
    end
    count
  end

  def setsockopt(stream : LibMongoC::Stream*, level : Int32, optname : Int32, optval : Void*, optlen : Int32)
    io, _ = @@registry[stream]
    LibC.setsockopt(io.fd, level, optname, optval, optlen)
  end

  def check_closed(stream : LibMongoC::Stream*)
    io = self.get_io(stream)
    io.closed?
  end

  def poll(stream_poll_array : LibMongoC::StreamPoll*, nstreams : Int32, _timeout_msec : Int32)
    (0...nstreams).each do |index|
      stream_poll = stream_poll_array[index]
      io = self.get_io(stream_poll.stream)
      stream_poll.revents = io.try &.closed? ? 0x08 : stream_poll.events
      stream_poll_array[index] = stream_poll
    end
    nstreams
  end

  def failed(stream : LibMongoC::Stream*)
    io = self.get_io(stream)
    io.close unless io.closed?
    if @@registry.has_key? stream
      @@registry.delete(stream)
      LibC.free(stream.as(Void*))
    end
  end

  def timed_out(_stream : LibMongoC::Stream*)
    false
  end

  def should_retry(_stream : LibMongoC::Stream*)
    false
  end

  def get_io(stream : LibMongoC::Stream*)
    io, host, port, connected = @@registry[stream]
    unless connected
      begin
        io.connect host, port
        @@registry[stream] = {io, host, port, true}
      rescue
      end
    end
    io
  end
end