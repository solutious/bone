
module Bone
  extend self
  
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
    resp = request :get, cid, key
  end
  
  def set(key, value, opts={})
    cid = opts[:cid] || CID
    value = File.readlines(value).join if File.exists?(value)
    resp = request :set, cid, key, :value => URI.encode(value)
    value
  end
  
  def request(action, cid, key, params={})
    params[:cid] = cid
    uri = "http://#{SOURCE}/#{action}/#{key}?"
    args = []
    params.each_pair {|n,v| args << "#{n}=#{URI.encode(v)}" }
    uri = URI.parse(uri << args.join('&'))
    Bone.ld "URI: #{uri}"
    Net::HTTP.get(uri)
  rescue SocketError => ex
    STDERR.puts "No boned"
    STDERR.puts ex.message, ex.backtrace if Drydock.debug?
    exit 1
  end
  
  module Aware
    def bone(key)
    end
  end
  
end

