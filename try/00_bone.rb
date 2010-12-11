# try try/00_bone.rb

ENV['BONE_SOURCE'] = 'http://bogus:3073'
require 'bone'

#ENV['BONE_TOKEN'] = '1c397d204aa4e94f566d7f78cc4bb5bef5b558d9bd64c1d8a45e67a621fb87dc'

## Can set the base uri via ENV 
## (NOTE: must be set before the require)
Bone::API.base_uri
#=> 'http://bogus:3073'

## Can set the base uri directly
Bone::API.base_uri "http://localhost:3073"
Bone::API.base_uri
#=> "http://localhost:3073"

## Empty key returns nil
Bone['bogus']
#=> nil

## Make request to API directly
Bone::API.get 'bogus'
##=> nil
