
module Bone
  extend self
  
  SOURCE = ENV['BONE_SOURCE'] || "localhost"
  CID = 'a462b9ebda71f16cb1567ba8704695ae8dba9999'
  
  def get(cid, key)
    resp = request :get, cid, key
  end
  
  def set(cid, key, value)
    value = File.readlines(value).join if File.exists?(value)
    resp = request :set, cid, key, :value => URI.encode(value)
    value
  end
  
  def request(a, cid, key, params={})
    uri_str = "http://#{SOURCE}:3000/#{a}/#{key}?cid=#{cid}"
    params.each_pair {|n,v| uri_str << "&#{n}=#{v}" }
    #p uri_str
    uri = URI.parse uri_str
    Net::HTTP.get(uri)
  end
  
  module Aware
    def bone(key)
    end
  end
  
end

