
ENV['BONE_SOURCE'] = 'redis://localhost:8045'
require 'bone'
Bone.debug = true


## Bone::API::Redis::Token.redis_objects
Bone::API::Redis::Token.redis_objects.keys
#=> [:secret, :keys]

## Bone::API::Redis::Token.redis_objects
Bone::API::Redis::Token.class_redis_objects.keys
#=> [:tokens]

## Bone::API::Redis::Token.new
@tobj = Bone::API::Redis::Token.new :atoken
@tobj.rediskey
#=> 'v2:bone:token:atoken:object'

## Bone::API::Redis::Token#secret
@tobj.secret.class
#=> Familia::Object::String

## Bone::API::Redis::Token#secret= doesn't exist
@tobj.secret = :poop
#=> :poop

## Bone::API::Redis::Token#secret isn't affected by secret=
@tobj.secret.class
#=> Familia::Object::String

## Bone::API::Redis::Token#secret to_s
@tobj.secret.to_s
#=> 'poop'

## Bone::API::Redis::Key.redis_objects
Bone::API::Redis::Key.redis_objects.keys
#=> [:value]

## Bone::API::Redis::Key.new
@kobj = Bone::API::Redis::Key.new :atoken, :akey
@kobj.rediskey
#=> 'v2:bone:key:atoken:global:akey:object'

## Bone::API::Redis::Key#value
@kobj.value.class
#=> Familia::Object::String

## Bone::API::Redis::Key#value to_s returns empty string
@kobj.value.to_s
#=> ''

## Bone::API::Redis::Key#value get returns nil
@kobj.value.get
#=> nil

## Bone::API::Redis::Key#value=
@kobj.value = 'avalue1'
#=> 'avalue1'

## Bone::API::Redis::Key#value set
@kobj.value.set 'avalue2'
#=> 'avalue2'

## Bone::API::Redis::Key#value clear
@kobj.value.clear
#=> 1

