require 'uri'
require 'net/http'

unless defined?(BONE_HOME)
  BONE_HOME = File.expand_path(File.join(File.dirname(__FILE__), '..') )
end

module Bone
  extend self
  VERSION = "0.1.0"
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
  TOKEN = ENV['BONE_TOKEN'].freeze
  
  def get(key, opts={})
    cid = opts[:cid] || ENV['BONE_TOKEN'] || TOKEN
    response *request(:get, cid, key)
  end
  
  def set(key, value, opts={})
    cid = opts[:cid] || ENV['BONE_TOKEN'] || TOKEN
    opts[:value] = value
    response *request(:set, cid, key, opts)
  end
  
  def [](keyname)
    get(keyname)
  end
  
  def []=(keyname, value)
    set(keyname, value)
  end
  
  def keys(keyname=nil, opts={})
    cid = opts[:cid] || ENV['BONE_TOKEN'] || TOKEN
    response *request(:keys, cid, keyname, opts)
  end
  
  # <tt>require</tt> a library from the vendor directory.
  # The vendor directory should be organized such
  # that +name+ and +version+ can be used to create
  # the path to the library. 
  #
  # e.g.
  # 
  #     vendor/httpclient-2.1.5.2/httpclient
  #
  def require_vendor(name, version)
    path = File.join(BONE_HOME, 'vendor', "#{name}-#{version}", 'lib')
    $:.unshift path
    Bone.ld "REQUIRE VENDOR: ", path
    require name
  end
  
  
  private
  
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
    STDERR.puts ex.message, ex.backtrace if Bone.debug?
    exit 1
  end
  
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
  

end

