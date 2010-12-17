# try try/20_instance_try.rb

# To prevent from loading the HTTP lib
ENV['BONE_SOURCE'] = 'memory://localhost'
require 'bone'
#Bone.debug = true
Bone.source = 'memory://localhost'

## Bone.generate
t, s = *Bone.generate
[t.size, s.size]
#=> [24, 64]

## Bone.generate (again, to see the values)
@t, @s = *Bone.generate
[@t, @s]
#=> [@t, @s]