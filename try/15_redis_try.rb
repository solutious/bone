
require 'bone'
Bone.debug = true
Bone.source = 'redis://localhost:8045'
@token = Bone.generate_token :secret


## Create Key
@bkey = Bone::API::Redis::Key.new @token, :greg
@bkey.id
#=> [@token, 'greg'].join(':')

## poop
@bkey.redis_field_key(:poop)
#=> true
