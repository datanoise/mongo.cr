require "../src/bson"
require "benchmark"

def runme
  query = [{"$match" => {"status" => "A"}},
           {"$group" => {"_id" => "$cust_id", "total" => {"$sum" => "$amount"}}}]
  bson_query = query.to_bson
  bson_query.invalidate
end

cnt = 0
n = 1000
loop do
  GC.collect
  puts "PRE RUN #{GC.stats.heap_size}"
  Benchmark.bm do |x|
    x.report("times:") do
      n.times do
        runme
      end
    end
  end
  GC.collect
  puts "POST RUN #{GC.stats.heap_size}"
  sleep 3
  puts "loop is #{cnt}"
  cnt += 1
end
