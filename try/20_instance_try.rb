# try try/20_instance_try.rb

require 'bone'
#Bone.debug = true
Bone.source = 'memory://localhost'

@token, @secret = *Bone.generate

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

