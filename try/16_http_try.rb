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
  :not_used_in_sig => nil,
  :arbitrary => '&+ ~ *%'
}
@now = Bone::API::HTTP.canonical_time Time.at(1292396472)

## Check Bone::API::HTTP.canonical_time
@now
#=> '2010-12-15T07:01:12Z'

## Bone::API::HTTP.canonical_host
Bone::API::HTTP.canonical_host Bone.source
#=> 'localhost:80'

## Bone::API::HTTP.canonical_sig_string (arbitrary query)
Bone::API::HTTP.canonical_sig_string Bone.source, :get, @path, @query
#=> "get\nlocalhost:80\n/v2/atoken/keys\narbitrary=%26%2B%20~%20%2A%25&token=atoken&zang=excellent"

## Bone::API::HTTP.encode (arbitrary query)
str = Bone::API::HTTP.canonical_sig_string Bone.source, :get, @path, @query
Bone::API::HTTP.encode @secret, str
#=> 'pMcaC09d8CHa%2BzU4MnOvWlrkn%2FIRNKkL6Ji1cYBySQ4%3D'

## Bone::API::HTTP.generate_signature (arbitrary query)
Bone::API::HTTP.generate_signature @secret, Bone.source, :get, @path, @query
#=> 'pMcaC09d8CHa%2BzU4MnOvWlrkn%2FIRNKkL6Ji1cYBySQ4%3D'

## Bone::API::HTTP.sign_query (arbitrary query)
Bone::API::HTTP.sign_query(Bone.token, @secret, :get, @path, @query)
#=> {:not_used_in_sig=>nil, :arbitrary=>"&+ ~ *%", "sig"=>"pMcaC09d8CHa%2BzU4MnOvWlrkn%2FIRNKkL6Ji1cYBySQ4%3D", :token=>"atoken", :zang=>:excellent}

## Bone::API::HTTP.prepare_query
query = Bone::API::HTTP.prepare_query @query, Bone.token, @now
#=> {:not_used_in_sig=>nil, "token"=>"atoken", :arbitrary=>"&+ ~ *%", :token=>"atoken", "stamp"=>"2010-12-15T07:01:12Z", "sigversion"=>"v1", :zang=>:excellent, "apiversion"=>"v2"}

## Bone::API::HTTP.generate_signature (prepared query)
query = Bone::API::HTTP.prepare_query @query, Bone.token, @now
Bone::API::HTTP.generate_signature @secret, Bone.source, :get, @path, query
#=> 'D2wTyNysYQE5%2BzXGfHwTf9JlsIYWnrldh1tqwbB7b%2Fg%3D'

## Bone::API::HTTP.sign_query (prepared query)
query = Bone::API::HTTP.prepare_query @query, Bone.token, @now
Bone::API::HTTP.sign_query Bone.token, @secret, :get, @path, query
#=> {"token"=>"atoken", :not_used_in_sig=>nil, :arbitrary=>"&+ ~ *%", "sig"=>"D2wTyNysYQE5%2BzXGfHwTf9JlsIYWnrldh1tqwbB7b%2Fg%3D", :token=>"atoken", "stamp"=>"2010-12-15T07:01:12Z", "sigversion"=>"v1", "apiversion"=>"v2", :zang=>:excellent}

## Bone::API::HTTP.generate_signature (an example of unique signatures)
query = Bone::API::HTTP.prepare_query @query, Bone.token
@sig = Bone::API::HTTP.generate_signature @secret, Bone.source, :get, @path, query
@sig
#=> @sig


