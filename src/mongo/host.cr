class Mongo::Host
  @host : String
  @port : UInt16
  @family : Int32

  getter host
  getter port
  getter family

  def initialize(@host, @port, @family)
  end

  def self.hosts(handle : LibMongoC::HostList)
    hosts = [] of Host
    cur = handle
    loop do
      break if cur.null?
      hosts << Host.new(String.new(cur.value.host.to_unsafe), cur.value.port, cur.value.family)
      cur = cur.value.next
      break if cur.null?
    end
    hosts
  end
end
