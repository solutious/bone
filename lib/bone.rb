require 'uri'
require 'net/http'

unless defined?(BONE_HOME)
  BONE_HOME = File.expand_path(File.join(File.dirname(__FILE__), '..') )
end

module Bone
  extend self
  VERSION = "0.2.0"
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
  
  def get(key, opts={})
    token = opts[:token] || ENV['BONE_TOKEN'] || TOKEN
    request(:get, token, key)
    key
  end
  
  def set(key, value, opts={})
    token = opts[:token] || ENV['BONE_TOKEN'] || TOKEN
    opts[:value] = value
    request(:set, token, key, opts)
    key
  end
  
  def [](keyname)
    get(keyname)
  end
  
  def []=(keyname, value)
    set(keyname, value)
  end
  
  def keys(keyname=nil, opts={})
    token = opts[:token] || ENV['BONE_TOKEN'] || TOKEN
    request(:keys, token, keyname, opts)
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
  
  private
  
  def request(action, token, key, params={})
    params[:token] = token
    path = "/#{APIVERSION}/#{action}/#{key}"
    host, port = *SOURCE.split(':')
    port ||= 6043
    
    Bone.ld "URI: #{path}"
    Bone.ld "PARAMS: " << params.inspect
    
    if action == :set
      query = {}
      params.each_pair {|n,v| query[n.to_s] = v } 
      req = Net::HTTP::Post.new(path)
      req.set_form_data query
    else
      args = []
      params.each_pair {|n,v| args << "#{n}=#{URI.encode(v.to_s)}" }     
      query = [path, args.join('&')].join('?') 
      Bone.ld "GET: #{query}"
      req = Net::HTTP::Get.new(query)
    end
    res = Net::HTTP.start(host, port) {|http| http.request(req) }
    case res
    when Net::HTTPSuccess, Net::HTTPRedirection
      res.body
    else
      raise Bone::Problem, "#{res.body} (#{res.code} #{res.message})"
    end
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

