# try try/20_instance_try.rb

ENV['BONE_SOURCE'] = 'memory://localhost'
require 'bone'
Bone.debug = true

@token = Bone.generate_token :secret

## create bone instance
@bone = Bone.new @token
@bone.class
#=> Bone

## set 
@bone.set :nerve, :centre
#=> 'centre'

## get 
@bone.get :nerve
#=> 'centre'

## []=
@bone[:nasty] = :fine
#=> :fine

## []
@bone[:nasty]
#=> 'fine'

