# mongo.cr

This library provides binding for MongoDB C Driver.

# Status

*Beta*

# Requirements

- Crystal language version 0.7.6 and higher.
- libmongoc version 1.1.0
- libbson verion 1.1.0

On Mac OSX use `homebrew` to install the required libraries:

```
$ brew install libbson
$ brew install mongo-c
```

# Goal

The goal is to provide a driver to access MongoDB.

# Usage

```crystal
require "./mongo"

client = Mongo::Client.new "mongodb://localhost"
db = client["my_db"]

collection = db["my_collection"]
collection.insert({"name" => "James Bond", "age" => 37})

collection.find({"age" => {"$gt" => 30}}) do |doc|
  puts doc
end
```

# License

MIT clause - see LICENSE for more details.


