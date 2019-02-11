# mongo.cr

This library provides binding for MongoDB C Driver. The goal is to provide a driver to access MongoDB.

# Status

*Beta*

# Requirements

- Crystal language version 0.27.0 and higher.
- libmongoc version 1.1.0
- libbson verion 1.1.0

On Mac OSX use `homebrew` to install the required libraries:

```
$ brew install mongo-c
```

On Linux you need to install `libmongoc-1.1-0` and `libbson-1.1-0` from your package manager or from source:

```
wget https://github.com/mongodb/mongo-c-driver/releases/download/1.1.0/mongo-c-driver-1.1.0.tar.gz
tar -zxvf mongo-c-driver-1.1.0.tar.gz && cd mongo-c-driver-1.1.0/
./configure --prefix=/usr --libdir=/usr/lib64
make
sudo make install
```

## Installation

Add this to your application's `shard.yml`:

```yaml
mongo:
  github: datanoise/mongo.cr
  branch: master
```

# Usage

```crystal
require "mongo"

client = Mongo::Client.new "mongodb://<user>:<password>@<host>:<port>/<db_name>"
db = client["db_name"]

collection = db["collection_name"]
collection.insert({ "name" => "James Bond", "age" => 37 })

collection.find({ "age" => { "$gt" => 30 } }) do |doc|
  puts typeof(doc)    # => BSON
  puts doc
end
```

# License

MIT clause - see LICENSE for more details.
