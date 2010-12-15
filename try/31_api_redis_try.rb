# try try/31_api_redis_try.rb

require 'bone'
#Bone.debug = true
@token = 'atoken'

## Can set the base uri without a token
Bone.source = 'redis://localhost:8045'
#=> 'redis://localhost:8045'

## Knows to use the redis API
Bone.api
#=> Bone::API::Redis

## Can generate a token
t = Bone.generate_token(:secret) || ''
t.size
#=> 40

## Can register a token
token = Bone.register_token @token, :secret
#=> 'atoken'

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
Bone.api.get Bone.token, Bone.secret, 'bogus'
#=> nil

## Set a value
Bone['akey1'] = 'value1'
Bone['akey1']
#=> 'value1'

## Get a value
Bone['akey1']
#=> 'value1'

## Knows all keys
Bone.keys
#=> ["akey1"]

## Knows when a key exists
Bone.key? :akey1
#=> true

## Knows when a key doesn't exist
Bone.key? :bogus
#=> false

## Bone.generate_token
@token2 = Bone.generate_token(:secret) || ''
@token2.size
#=> 40

Bone.destroy_token @token
Bone.destroy_token @token2