# try try/32_api_http_try.rb

require 'bone'



## Can set the base uri directly
Bone.source = "http://localhost:3073"
Bone.source.to_s
##=> "http://localhost:3073"

## Knows to use the redis HTTP
Bone.api
##=> Bone::API::HTTP

## Empty key returns nil
Bone['bogus']
##=> nil

## Make request to API directly
Bone::API.get 'bogus'
##=> nil
