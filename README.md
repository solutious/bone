## Bone - 0.3 ##

**Remote environment variables**

*NOTE: This version is not compatible with previous versions of Bone.*

## Features

* Store variables and files remotely
* A command-line and ruby interface
* Secure REST API (based on AWS sig)
* Also supports direct [Redis](http://code.google.com/p/redis/) access.

## CLI Example
        
    # Specify arbitrary keys and values. 
    $ bone set cust_id c397d204aa4e94f566d7f78c
    $ bone cust_id
    c397d204aa4e94f566d7f78c
    
    # Set values from STDIN
    $ >config/redis-server.conf bone set redis_conf 
    $ bone redis_conf 
    [content of redis-server.conf]
    
    # The data doesn't have to be text
    $ >path/2/dog.jpg bone set dog_picture
    $ bone dog_picture > dog.jpg 
    $ open dog.jpg
    
    # Show all available keys
    $ bone keys
    cust_id
    redis_conf
    dog_picture
    
## Ruby Example

    require 'bone'
    
    Bone[:cust_id] = 'c397d204aa4e94f566d7f78c'
    Bone[:redis_conf] = File.read('config/redis-server.conf')
    
    Bone[:cust_id]                    # => "c397d204aa4e94f566d7f78c"
    Bone[:redis_conf]                 # => "[content of redis-server.conf]"
    
    # OR
    
    bone = Bone.new
    bone[:latest_backup] = 'redis.rdb-2011-01-01'
    bone.keys                         # => ['cust_id', 'latest_backup', 'redis_conf']
    
## Setting BONE_SOURCE ##

Bone can store data via a REST API or directly to Redis. The default source is redis://127.0.0.1:6379. 

### Redis ###

If you are running [Redis](http://code.google.com/p/redis/) at a different address or port, you can change it by setting the BONE_SOURCE environment variable or by explicitly setting in Ruby with `Bone.source='redis://anotherhost:6379'`.

### HTTP ###

If you want to use the REST API, you need to run an instance of [boned](http://github.com/solutious/boned) (the bone daemon).You'd then set your bone source to something like `https://somehost:3073`. **Note: unless your bone client and server are on a private network, it is highly recommended to use HTTPS.**

### The Bonery ###

You can use the Bone daemon hosted at [The Bonery](http://bonery.com/). You'll need to [generate a token](https://api.bonery.com/signup/alpha) and set your BONE_SOURCE to `https://api.bonery.com/`.


## Installation

    $ sudo gem install bone
    
    $ bone generate
    # Your token for http://localhost:3073
    BONE_TOKEN=LBL6PEGVWLFR3PJIOFQG01GN
    BONE_SECRET=tXvhnban0HD.Aqj$goK9a2oW$T/L8le9460cfXR1t^RfMXq.5vQ2^lHd-c.WND6V
    
    [Add BONE_TOKEN and BONE_SECRET to your .bashrc or equivalent]
    
    $ bone


## Credits

* Delano Mandelbaum (http://solutious.com)
* Query signatures for the HTTP API are based on / stolen from: https://github.com/grempe/amazon-ec2/blob/master/lib/AWS.rb


## Thanks 

* Kalin Harvey and Marc-André Cournoyer for the early feedback.


## License

Copyright (c) 2009-2011 Delano Mandelbaum, Solutious Inc.

Distributes under the same terms as Ruby
