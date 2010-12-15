# try try/30_api_redis_try.rb

ENV['BONE_SOURCE'] = 'memory://localhost'
require 'bone'
#Bone.debug = true

## Can set the base uri via ENV 
## (NOTE: must be set before the require)
Bone.source.to_s
#=> 'memory://localhost'

## Knows to use the redis API
Bone.api
#=> Bone::API::Memory

## Can generate a token
t = Bone.generate_token :secret
t.size
#=> 40

## Can register a token
@token = Bone.register_token 'atoken', :secret
@token
#=> 'atoken'

## Can set the base uri directly
Bone.source = "memory://#{@token}@localhost"
Bone.source.to_s
#=> "memory://#{@token}@localhost"

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
#=> ["v2:bone:#{@token}:valid"]

## Knows when a key exists
Bone.key? :valid
#=> true

## Knows when a key doesn't exist
Bone.key? :bogus
#=> false


Bone.destroy_token @token