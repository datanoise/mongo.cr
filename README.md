# mongo.cr

[![Build Status](https://travis-ci.org/elbywan/mongo.cr.svg?branch=master)](https://travis-ci.org/elbywan/mongo.cr)

#### This library provides bindings to the MongoDB C Driver.

# Status

*Beta*

# Requirements

- Crystal language version 0.34 and higher.
- libmongoc *(recommended versions: >= 1.15.3)*
- libbson

On Mac OSX use `homebrew` to install the required libraries:

```
$ brew install mongo-c
```

On Linux you need to install `libmongoc` and `libbson` from your package manager or from source.

See [the official guide](http://mongoc.org/libmongoc/current/installing.html).

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
collection.insert({ name: "James Bond", age: 37 })

collection.find({ age: { "$gt": 30 }}) do |doc|
  puts typeof(doc)    # => BSON
  puts doc
end
```

# License

MIT clause - see LICENSE for more details.
