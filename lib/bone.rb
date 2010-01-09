require 'uri'
require 'net/http'

unless defined?(BONE_HOME)
  BONE_HOME = File.expand_path(File.join(File.dirname(__FILE__), '..') )
end

module Bone
  extend self
  VERSION = "0.2.3"
  APIVERSION = 'v1'.freeze
  
  class Problem < RuntimeError; end
  class BadBone < Problem; end
  
  @digest_type = nil  # set at the end
  @debug = false
  class << self
    attr_accessor :digest_type
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
  
  # Get a key from the boned server. Same as `get!`  
  # but does not raise an exception for an unknown key.
  def get(key, opts={})
    get! key, opts
  rescue Bone::Problem
    nil
  end
  
  # Get a key from the boned server. Raises an exception 
  # for an unknown key.
  def get!(key, opts={})
    token = opts[:token] || ENV['BONE_TOKEN'] || TOKEN
    request(:get, token, key) # returns the response body
  end
  
  def set(key, value, opts={})
    token = opts[:token] || ENV['BONE_TOKEN'] || TOKEN
    opts[:value] = value
    request(:set, token, key, opts)
    key # return the key b/c it could be a binary file
  end
  
  def del(key, opts={})
    token = opts[:token] || ENV['BONE_TOKEN'] || TOKEN
    request(:del, token, key, opts) # returns the response body
  end
  
  def [](keyname)
    get(keyname)
  end
  
  def []=(keyname, value)
    set(keyname, value)
  end
  
  def keys(keyname=nil, opts={})
    token = opts[:token] || ENV['BONE_TOKEN'] || TOKEN
    k = request(:keys, token, keyname, opts)
    k.split($/)
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
  
  def valid_token?(val)
    is_sha256? val
  end
  
  def is_sha1?(val)
    val.to_s.match /\A[0-9a-f]{40}\z/
  end
  
  def is_sha256?(val)
    val.to_s.match /\A[0-9a-f]{64}\z/
  end
  
  def digest(val)
    @digest_type.hexdigest val
  end
  
  def generate_token
    srand
    digest [`hostname`, `w`, Time.now, rand].join(':')
  end
  alias_method :token, :generate_token
  
  private
  
  def request(action, token, key, params={})
    params[:token] = token
    path = "/#{APIVERSION}/#{action}/#{key}"
    host, port = *SOURCE.split(':')
    port ||= 6043
    
    Bone.ld "URI: #{path}"
    Bone.ld "PARAMS: " << params.inspect
    
    case action
    when :del
      headers = { 'X-BONE_TOKEN' => token }
      req = Net::HTTP::Delete.new(path, headers)
    when :set
      query = {}
      params.each_pair {|n,v| query[n.to_s] = v } 
      req = Net::HTTP::Post.new(path)
      req.set_form_data query
    when :get, :keys
      args = []
      params.each_pair {|n,v| args << "#{n}=#{URI.encode(v.to_s)}" }     
      query = [path, args.join('&')].join('?') 
      Bone.ld "GET: #{query}"
      req = Net::HTTP::Get.new(query)
    else
      raise Bone::Problem, "Unknown action: #{action}"
    end
    res = Net::HTTP.start(host, port) {|http| http.request(req) }
    case res
    when Net::HTTPSuccess, Net::HTTPRedirection
      res.body
    else
      raise Bone::Problem, "#{res.body} (#{res.code} #{res.message})"
    end
  rescue Errno::ECONNREFUSED => ex
    raise Bone::Problem, "No boned"
  end
  
  def determine_digest_type
    if RUBY_PLATFORM == "java"
      require 'openssl'
      Bone.digest_type = OpenSSL::Digest::SHA256
    else
      require 'digest'
      Bone.digest_type = Digest::SHA256
    end
  end
  
  @digest_type = determine_digest_type
end

