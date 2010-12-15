# try try/32_api_http_try.rb

require 'bone'
#Bone.debug = true
Bone.token = 'atoken'
Bone.secret = 'crystal'

## Can set the base uri directly
Bone.source = "http://localhost:3073"
Bone.source.to_s
#=> "http://localhost:3073"

## Knows to use the redis HTTP
Bone.api
#=> Bone::API::HTTP

## Bone.register_token
Bone.register_token Bone.token, Bone.secret
#=> 'atoken'

## Can set the base uri directly
Bone.source = "http://#{Bone.token}@localhost:3073"
Bone.source.to_s
#=> "http://#{Bone.token}@localhost:3073"

## Bone.token? knows when a token exists
Bone.token? Bone.token
#=> true

## Bone.token? returns false when it doesn't exist
Bone.token? 'bogus'
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
@token2 = Bone.generate_token(Bone.secret) || ''
@token2.size
#=> 40

Bone.destroy_token Bone.token
Bone.destroy_token @token2 if @token2
