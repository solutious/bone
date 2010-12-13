# try try/31_api_redis_try.rb

ENV['BONE_SOURCE'] = 'redis://localhost:8045'
require 'bone'
Bone.debug = true

## Can set the base uri via ENV 
## (NOTE: must be set before the require)
Bone.source.to_s
#=> 'redis://localhost:8045'

## Knows to use the redis API
Bone.api
#=> Bone::API::Redis

## Can register a token
@token = Bone.generate_token :secret
@token.size
#=> 40

## Can set the base uri directly
Bone.source = "redis://#{@token}@localhost:8045"
Bone.source.to_s
#=> "redis://#{@token}@localhost:8045"

## Knows a valid token
Bone.token? @token
#=> true

## Knows an invalid token
Bone.token? 'bogustoken'
#=> false

## Empty key returns nil
Bone['bogus']
#=> nil

## Make request to API directly
Bone.api.get Bone.token, 'bogus'
#=> nil

## Set a value
Bone['valid'] = true
Bone['valid']
#=> 'true'

## Get a value
Bone['valid']
#=> 'true'

## Knows all keys
Bone.keys
#=> ["v2:bone:#{@token}:valid:value"]

## Knows when a key exists
Bone.key? :valid
#=> true

## Knows when a key doesn't exist
Bone.key? :bogus
#=> false


Bone.destroy_token @token