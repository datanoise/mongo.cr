class Mongo::Host
  getter host : String
  getter port : UInt16
  getter family : Int32

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
