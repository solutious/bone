# try try/11_bone_redis.rb

ENV['BONE_SOURCE'] = 'redis://bogus1:8045'
require 'bone'

## Can set the base uri via ENV 
## (NOTE: must be set before the require)
Bone.source.to_s
#=> 'redis://bogus1:8045'

## Can set the base uri directly
Bone.source = 'redis://localhost:8045'
Bone.source.to_s
#=> "redis://localhost:8045"

## Knows to use the redis API
Bone.api
#=> Bone::API::Redis

## Empty key returns nil
Bone['bogus']
#=> nil

## Make request to API directly
Bone.api.get 'bogus'
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
#=> ['v2:bone:valid:value']

## Knows when a key exists
Bone.key? :valid
#=> true

## Knows when a key doesn't exist
Bone.key? :bogus
#=> false