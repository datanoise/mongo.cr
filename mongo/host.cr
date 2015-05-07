class Mongo::Host
  getter host
  getter port
  getter family

  def initialize(@host, @port, @family)
  end

  def self.hosts(handle: LibMongoC::HostList)
    hosts = [] of Host
    cur = handle
    loop do
      break if cur.nil?
      hosts << Host.new(String.new(cur.value.host.buffer), cur.value.port, cur.value.family)
      cur = cur.value.next
      break if cur.nil?
    end
    hosts
  end
end

