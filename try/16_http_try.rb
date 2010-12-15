# try try/20_instance_try.rb

ENV['BONE_TOKEN'] = "atoken"
ENV['BONE_SOURCE'] = 'memory://localhost'
require 'bone'
#Bone.debug = true

@secret = "poop"
@path = "/#{Bone::APIVERSION}/#{Bone.token}/keys"
@query = {
  :token => Bone.token,
  :zang => :excellent,
  :not_used_in_sig => nil,
  :arbitrary => '&+ ~ *%'
}
@now = Bone::API::HTTP.canonical_time Time.at(1292396472)

## Check Bone::API::HTTP.canonical_time
@now
#=> '2010-12-15T07:01:12Z'

## Bone::API::HTTP.canonical_sig_string
Bone::API::HTTP.canonical_sig_string Bone.source.host, :get, @path, @query
#=> "get\nlocalhost\n/v2/atoken/keys\narbitrary=%26%2B%20~%20%2A%25&token=atoken&zang=excellent"

## Bone::API::HTTP.encode
str = Bone::API::HTTP.canonical_sig_string Bone.source.host, :get, @path, @query
Bone::API::HTTP.encode @secret, str
#=> 'HcXDbYsRVL2eGBiKYcaxai8A4%2ByALTjYWeEgcgIrpMA%3D'

## Bone::API::HTTP.generate_signature
Bone::API::HTTP.generate_signature @secret, Bone.source.host, :get, @path, @query
#=> 'HcXDbYsRVL2eGBiKYcaxai8A4%2ByALTjYWeEgcgIrpMA%3D'

## Bone::API::HTTP.sign_query (arbitrary query)
Bone::API::HTTP.sign_query Bone.token, @secret, :get, @path, @query
#=> 'arbitrary=%26%2B+%7E+%2A%25&not_used_in_sig=&token=atoken&zang=excellent&sig=HcXDbYsRVL2eGBiKYcaxai8A4%2ByALTjYWeEgcgIrpMA%3D'

## Bone::API::HTTP.prepare_query
query = Bone::API::HTTP.prepare_query @query, Bone.token, @now
query.keys.collect(&:to_s).sort
#=> ["apiversion", "arbitrary", "not_used_in_sig", "sigversion", "stamp", "token", "token", "zang"]

## Bone::API::HTTP.sign_query (prepared query)
query = Bone::API::HTTP.prepare_query @query, Bone.token, @now
Bone::API::HTTP.sign_query Bone.token, @secret, :get, @path, query
#=> 'apiversion=v2&arbitrary=%26%2B+%7E+%2A%25&not_used_in_sig=&sigversion=v1&stamp=2010-12-15T07%3A01%3A12Z&token=atoken&token=atoken&zang=excellent&sig=V3ifEwipED3DhOQ7YlVx89qRQeAOqPBtDUXeJZkUO9E%3D'