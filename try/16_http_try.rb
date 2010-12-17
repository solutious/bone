# try try/20_instance_try.rb

require 'bone'
#Bone.debug = true
Bone.token = 'atoken'
Bone.source = 'memory://localhost'

@secret = "wHLJ3PskyzcxN9A9fYdQKltxDhsw2E%2B%2BUoL%2BbfOp2DM"
@path = "/#{Bone::APIVERSION}/#{Bone.token}/keys"
@query = {
  :token => Bone.token,
  :zang => :excellent,
  :a_nil_value => nil,
  :arbitrary => '&+ ~ *%'
}
@body = 'nuprin'
@now = Bone::API::HTTP.canonical_time Time.at(1292396472)

## Check Bone::API::HTTP.canonical_time
@now
#=> 1292396472

## Bone::API::HTTP.canonical_host
Bone::API::HTTP.canonical_host Bone.source
#=> 'localhost:80'

## Bone::API::HTTP.canonical_sig_string (arbitrary query)
Bone::API::HTTP.canonical_sig_string Bone.source, :get, @path, @query
#=> "get\nlocalhost:80\n/v2/atoken/keys\na_nil_value=&arbitrary=%26%2B%20~%20%2A%25&token=atoken&zang=excellent"

## Bone::API::HTTP.encode (arbitrary query)
str = Bone::API::HTTP.canonical_sig_string Bone.source, :get, @path, @query
Bone::API::HTTP.encode @secret, str
#=> 'rfJY5F3j2Ndq9inSbbA2%2FKzvd%2By5eGqR5kMu4HCDM4I%3D'

## Bone::API::HTTP.encode (arbitrary query, no escape)
str = Bone::API::HTTP.canonical_sig_string Bone.source, :get, @path, @query
Bone::API::HTTP.encode @secret, str, false
#=> 'rfJY5F3j2Ndq9inSbbA2/Kzvd+y5eGqR5kMu4HCDM4I='

## Bone::API::HTTP.generate_signature (arbitrary query)
Bone::API::HTTP.generate_signature @secret, Bone.source, :get, @path, @query
#=> 'rfJY5F3j2Ndq9inSbbA2%2FKzvd%2By5eGqR5kMu4HCDM4I%3D'

## Bone::API::HTTP.sign_query (arbitrary query)
Bone::API::HTTP.sign_query(Bone.token, @secret, :get, @path, @query)
#=> {:token=>"atoken", :a_nil_value=>nil, :arbitrary=>"&+ ~ *%", "sig"=>"rfJY5F3j2Ndq9inSbbA2%2FKzvd%2By5eGqR5kMu4HCDM4I%3D", :zang=>:excellent}

## Bone::API::HTTP.encode (arbitrary query, with body)
str = Bone::API::HTTP.canonical_sig_string Bone.source, :get, @path, @query, @body
Bone::API::HTTP.encode @secret, str
#=> 'LK%2FghZKcGwNl7tSnEnr0pKGdBe%2BMwAjl5cl1ZBpT%2F%2F0%3D'

## Bone::API::HTTP.prepare_query
query = Bone::API::HTTP.prepare_query @query, Bone.token, @now
#=> {:token=>"atoken", :a_nil_value=>nil, "token"=>"atoken", :arbitrary=>"&+ ~ *%", "stamp"=>1292396472, "sigversion"=>"v2", :zang=>:excellent, "apiversion"=>"v2"}

## Bone::API::HTTP.generate_signature (prepared query)
query = Bone::API::HTTP.prepare_query @query, Bone.token, @now
Bone::API::HTTP.generate_signature @secret, Bone.source, :get, @path, query
#=> 'UY8s7hbquwWedOpr0g%2B4SyioKTbYSLalCjgvfUhl7eo%3D'

## Bone::API::HTTP.sign_query (prepared query)
query = Bone::API::HTTP.prepare_query @query, Bone.token, @now
Bone::API::HTTP.sign_query Bone.token, @secret, :get, @path, query
#=> {:token=>"atoken", "token"=>"atoken", :a_nil_value=>nil, :arbitrary=>"&+ ~ *%", "sig"=>"UY8s7hbquwWedOpr0g%2B4SyioKTbYSLalCjgvfUhl7eo%3D", "stamp"=>1292396472, "sigversion"=>"v2", "apiversion"=>"v2", :zang=>:excellent}

## Bone::API::HTTP.generate_signature (an example of unique signatures)
query = Bone::API::HTTP.prepare_query @query, Bone.token
@sig = Bone::API::HTTP.generate_signature @secret, Bone.source, :get, @path, query
#=> @sig

## Bone::API::HTTP.
