# try try/31_api_redis_try.rb

require 'bone'
#Bone.debug = true
@token = 'atoken'
@secret = Bone.create_secret

## Can set the base uri without a token
Bone.source = 'redis://localhost:8045'
#=> 'redis://localhost:8045'

## Knows to use the redis API
Bone.api
#=> Bone::API::Redis

## Can generate a token
@generated_token, secret = *Bone.generate
@generated_token.size
#=> 24

## Can register a token
token = Bone.register @token, @secret
#=> 'atoken'

## Can set token directly
Bone.token = @token
Bone.token
#=> @token

## Can check secret via API
Bone.api.secret @token
#=> @secret

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


Bone.destroy @token
Bone.destroy @generated_token