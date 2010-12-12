# try try/00_bone_http.rb

ENV['BONE_SOURCE'] = 'http://bogus:3073'
require 'bone'

#ENV['BONE_TOKEN'] = '1c397d204aa4e94f566d7f78cc4bb5bef5b558d9bd64c1d8a45e67a621fb87dc'

## Can set the base uri via ENV 
## (NOTE: must be set before the require)
Bone.source.to_s
#=> 'http://bogus:3073'

## Can set the base uri directly
Bone.source = "http://localhost:3073"
Bone.source.to_s
#=> "http://localhost:3073"

## Knows to use the redis HTTP
Bone.api
#=> Bone::API::HTTP


## Empty key returns nil
Bone['bogus']
#=> nil

## Make request to API directly
Bone::API.get 'bogus'
##=> nil
