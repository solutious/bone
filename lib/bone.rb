
module Bone
  extend self
  APIVERSION = 'v1'.freeze
  
  @debug = false
  class << self
    def enable_debug()  @debug = true  end
    def disable_debug() @debug = false end
    def debug?()        @debug == true end
    def ld(*msg)
      return unless Bone.debug?
      prefix = "D(#{Thread.current.object_id}):  "
      STDERR.puts "#{prefix}" << msg.join("#{$/}#{prefix}")
    end
  end
  
  SOURCE = (ENV['BONE_SOURCE'] || "localhost:6043").freeze
  CID = ENV['BONE_CID'].freeze
  
  def get(key, opts={})
    cid = opts[:cid] || CID
    response *request(:get, cid, key)
  end
  
  def set(key, value, opts={})
    cid = opts[:cid] || CID
    if File.exists?(value)
      value = File.readlines(value).join
      opts[:file] = true
    end
    opts[:value] = value
    response *request( :set, cid, key, opts)
  end
  
  private
  
  def response(*args)
    resp, body = *args
    Bone.ld resp.inspect, body.inspect
    if Net::HTTPBadRequest === resp
      puts body
      exit 1
    else
      body
    end
  end
  
  def request(action, cid, key, params={})
    params[:cid] = cid
    path = "/#{APIVERSION}/#{action}/#{key}?"
    args = []
    params.each_pair {|n,v| args << "#{n}=#{URI.encode(v.to_s)}" }
    path << args.join('&')
    Bone.ld "URI: #{path}"
    host, port = *SOURCE.split(':')
    req = Net::HTTP.new(host, port || 6043)
    a, b = req.get(path)
    [a, b]
  rescue => ex
    STDERR.puts "No boned"
    STDERR.puts ex.message, ex.backtrace# if Drydock.debug?
    exit 1
  end
  
  module Aware
    def bone(key)
    end
  end
  
end

