
unless defined?(BONE_HOME)
  BONE_HOME = File.expand_path(File.join(File.dirname(__FILE__), '..') )
end

local_libs = %w{familia}
local_libs.each { |dir| 
  a = File.join(BONE_HOME, '..', '..', 'opensource', dir, 'lib')
  $:.unshift a
}

require 'familia'
require 'base64'
require 'openssl'
require 'digest/sha1'
require 'time'

class Bone
  module VERSION
    def self.to_s
      load_config
      [@version[:MAJOR], @version[:MINOR], @version[:PATCH]].join('.')
    end
    alias_method :inspect, :to_s
    def self.load_config
      require 'yaml'
      @version ||= YAML.load_file(File.join(BONE_HOME, '..', 'VERSION.yml'))
    end
  end
end


class Bone
  APIVERSION = 'v2'.freeze unless defined?(Bone::APIVERSION)
  @source = URI.parse(ENV['BONE_SOURCE'] || 'https://api.bonery.com')
  @apis = {}
  class Problem < RuntimeError; end
  class NoToken < Problem; end  
  class << self
    attr_accessor :debug
    attr_reader :apis, :api, :source
    attr_writer :token, :secret, :digest_type
    
    def source=(v)
      @source = URI.parse v
      select_api
    end
    
    def token
      @token || @source.user || ENV['BONE_TOKEN']
    end
    
    def secret 
      @secret || @source.password || ENV['BONE_SECRET']
    end
    
    def info *msg
      STDERR.puts *msg
    end
    
    def ld *msg
      info *msg if debug
    end
    
    # Stolen from Rack::Utils which stole it from Camping.
    def uri_escape(s)
      s.to_s.gsub(/([^ a-zA-Z0-9_.-]+)/n) {
        '%'+$1.unpack('H2'*bytesize($1)).join('%').upcase
      }.tr(' ', '+')
    end
    
    # Stolen from Rack::Utils which stole it from Camping.
    def uri_unescape(s)
      s.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n){
        [$1.delete('%')].pack('H*')
      }
    end
    
    # Return the bytesize of String; uses String#size under Ruby 1.8 and
    # String#bytesize under 1.9.
    if ''.respond_to?(:bytesize)
      def bytesize(string)
        string.bytesize
      end
    else
      def bytesize(string)
        string.size
      end
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

    def random_digest
      digest [$$, self.object_id, `hostname`, `w`, Time.now.to_f].join(':')
    end
    
    def select_api
      begin
        @api = Bone.apis[Bone.source.scheme.to_sym]
        raise RuntimeError, "Bad source: #{Bone.source}" if api.nil?
        @api.connect
      rescue => ex
        Bone.info "#{ex.class}: #{ex.message}", ex.backtrace
        exit
      end
    end
    
    def select_digest_type
      if RUBY_PLATFORM == "java"
        require 'openssl'
        @digest_type = OpenSSL::Digest::SHA1
      else
        require 'digest'
        @digest_type = Digest::SHA1
      end
    end
    
    def register_api(scheme, klass)
      Bone.apis[scheme.to_sym] = klass
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
  end
  
  
  module API
    module ClassMethods
      def get(name)
        new(Bone.token).get name
      end
      alias_method :[], :get
      def set(name, value)
        new(Bone.token).set name, value
      end
      alias_method :[]=, :set
      def keys(filter='*')
        new(Bone.token).keys filter
      end
      def key?(name)
        new(Bone.token).key? name
      end
      def register_token(token, secret)
        new(Bone.token).register_token token, secret
      end
      def generate_token(secret)
        new(Bone.token).generate_token secret
      end
      def destroy_token(token)
        new(Bone.token).destroy_token token
      end
      def token?(token)
        new(Bone.token).token? token
      end
    end
    module InstanceMethods
      attr_accessor :token, :secret
      def initialize(t, s=nil)
        @token, @secret = t, s
      end
      def get(name)
        carefully do
          raise_errors
          Bone.api.get token, secret, name
        end
      end
      alias_method :[], :get

      def set(name, value)
        carefully do
          raise_errors
          Bone.api.set token, secret, name, value
        end
      end
      alias_method :[]=, :set

      def keys(filter='*')
        carefully do
          raise_errors
          Bone.api.keys token, secret, filter
        end
      end
      
      def key?(name)
        carefully do
          raise_errors
          Bone.api.key? token, secret, name
        end
      end
      
      def register_token(this_token, this_secret)
        carefully do
          Bone.api.register_token this_token, this_secret
        end
      end
      
      def generate_token(this_secret)
        carefully do
          Bone.api.generate_token this_secret
        end
      end
      
      def destroy_token(token)
        carefully do
          Bone.api.destroy_token token, secret
        end
      end
      
      def token?(token)
        carefully do
          Bone.api.token? token, secret
        end
      end
      
      private 
      def raise_errors
        raise RuntimeError, "No token" unless token
        #raise RuntimeError, "Invalid token (#{token})" if !Bone.api.token?(token)
      end
      def carefully
        begin
          yield
        rescue => ex
          Bone.ld "#{ex.class}: #{ex.message}", ex.backtrace
          nil
        end
      end
    end
    
    module Helpers
      def path(*parts)
        "/#{APIVERSION}/" << parts.flatten.join('/')
      end
      def prefix(*parts)
        parts.flatten!
        parts.unshift *[APIVERSION, 'bone']
        parts.join(':')
      end
    end
    extend Bone::API::Helpers
    
  end
  
  require 'bone/api'
  include Bone::API::InstanceMethods
  extend Bone::API::ClassMethods
  select_api
  select_digest_type
end


