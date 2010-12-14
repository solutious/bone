
unless defined?(BONE_HOME)
  BONE_HOME = File.expand_path(File.join(File.dirname(__FILE__), '..') )
end

local_libs = %w{familia}
local_libs.each { |dir| 
  a = File.join(BONE_HOME, '..', '..', 'opensource', dir, 'lib')
  $:.unshift a
}

require 'httparty'
require 'familia'

class Bone
  module VERSION
    def self.to_s
      load_config
      [@version[:MAJOR], @version[:MINOR], @version[:PATCH]].join('.')
    end
    alias_method :inspect, :to_s
    def self.load_config
      require 'yaml'
      @version ||= YAML.load_file(File.join(BLUTH_LIB_HOME, '..', 'VERSION.yml'))
    end
  end
end


class Bone
  APIVERSION = 'v2'.freeze unless defined?(Bone::APIVERSION)
  @source = URI.parse(ENV['BONE_SOURCE'] || 'https://api.bonery.com')
  @apis = {}
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
      attr_accessor :token
      def initialize(t)
        @token = t
      end
      def get(name)
        carefully do
          raise_errors
          Bone.api.get token, name
        end
      end
      alias_method :[], :get

      def set(name, value)
        carefully do
          raise_errors
          Bone.api.set token, name, value
        end
      end
      alias_method :[]=, :set

      def keys(filter='*')
        carefully do
          raise_errors
          Bone.api.keys token, filter
        end
      end
      
      def key?(name)
        carefully do
          raise_errors
          Bone.api.key? token, name
        end
      end
      
      def generate_token(secret)
        carefully do
          Bone.api.generate_token secret
        end
      end
      
      def destroy_token(token)
        carefully do
          Bone.api.destroy_token token
        end
      end
      
      def token?(token)
        carefully do
          Bone.api.token? token
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
      def bonekey(token, name)
        [prefix, token, name, 'value'].join(':')
      end
      def prefix(*parts)
        parts.flatten!
        parts.unshift *[APIVERSION, 'bone']
        parts.join(':')
      end
    end
    extend Bone::API::Helpers
    
    module HTTP
      include HTTParty
      base_uri Bone.source.to_s
      class << self 
        # /v2/[name]
        def get(token, name, query={})
          debug_output $stderr if Bone.debug
          super(Bone::API.path(name), :query => query)
        end
        def connect
        end
      end
      Bone.register_api :http, self
      Bone.register_api :https, self
    end
    
    module Redis
      extend self
      attr_accessor :redis
      def get(token, name)
        Key.new(token, name).value.get   # get returns nil if not set
      end
      def set(token, name, value)
        Key.new(token, name).value = value
        Token.new(token).keys.add Time.now.utc.to_f, name
        value.to_s
      end
      def keys(token, filter='*')
        Token.new(token).keys.to_a
      end
      def key?(token, name)
        Key.new(token, name).value.exists?
      end
      def destroy_token(token)
        Token.tokens.delete token
        Token.new(token).secret.destroy!
      end
      def generate_token(secret)
        begin 
          token = Bone.random_digest
        end while token?(token)
        Token.tokens.add Time.now.utc.to_i, token
        t = Token.new(token).secret = secret
        token
      end
      def token?(token)
        Token.tokens.member?(token)
      end
      def connect
        Familia.uri = Bone.source
      end
      class Key
        include Familia
        prefix Bone::API.prefix(:key)
        string :value
        attr_reader :token, :name, :bucket
        def initialize(token, name, bucket=:global)
          @token, @name, @bucket = token, name, bucket
          initialize_redis_objects
        end
        def index
          [token, bucket, name].join(':')
        end
      end
      class Token
        include Familia
        prefix Bone::API.prefix(:token)
        index :token
        string :secret
        zset :keys
        class_zset :tokens
        attr_reader :token
        def initialize(token)
          @token = token
          initialize_redis_objects
        end
      end
      Bone.register_api :redis, self
    end
    
    module Memory
      extend self
      @data, @tokens = {}, {}
      def get(token, name)
        @data[Bone::API.bonekey(token, name)]
      end
      def set(token, name, value)
        @data[Bone::API.bonekey(token, name)] = value.to_s
      end
      def keys(token, filter='*')
        filter = '.+' if filter == '*'
        filter = Bone::API.bonekey(token, filter)
        @data.keys.select { |name| name =~ /#{filter}/ }
      end
      def key?(token, name)
        @data.has_key?(Bone::API.bonekey(token, name))
      end
      def destroy_token(token)
        @tokens.delete token
      end
      def generate_token(secret)
        begin 
          token = Bone.random_digest
        end while token?(token)
        @tokens[token] = secret
        token
      end
      def token?(token)
        @tokens.key?(token)
      end
      def connect
      end
      Bone.register_api :memory, self
    end
    
  end
  
  include Bone::API::InstanceMethods
  extend Bone::API::ClassMethods
  select_api
  select_digest_type
end


