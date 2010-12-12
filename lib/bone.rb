require 'httparty'

unless defined?(BONE_HOME)
  BONE_HOME = File.expand_path(File.join(File.dirname(__FILE__), '..') )
end

module Bone
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


module Bone
  APIVERSION = 'v2'.freeze unless defined?(Bone::APIVERSION)
  @source = URI.parse(ENV['BONE_SOURCE'] || 'https://api.bonery.com')
  @apis = {}
  class << self
    attr_accessor :debug
    attr_reader :source, :api, :apis
    
    def source=(v)
      @source = URI.parse v
      select_api
    end
    
    def info *msg
      STDERR.puts *msg
    end
    
    def ld *msg
      info *msg if debug
    end
    
    def carefully
      begin
        yield
      rescue => ex
        Bone.ld "#{ex.class}: #{ex.message}", ex.backtrace
        nil
      end
    end
    
    def select_api
      begin
        @api = Bone.apis[Bone.source.scheme.to_sym]
        @api.connect
        raise RuntimeError, "Bad source: #{Bone.source}" if api.nil?
      rescue => ex
        Bone.info "#{ex.class}: #{ex.message}", ex.backtrace
        exit
      end
    end
    
    def register_api(scheme, klass)
      Bone.apis[scheme.to_sym] = klass
    end
  end
  
  
  module API
    module ClassMethods
      def get(name)
        carefully do
          Bone.api.get name
        end
      end
      alias_method :[], :get

      def set(name, value)
        carefully do
          Bone.api.set name, value
        end
      end
      alias_method :[]=, :set

      def keys(filter='*')
        carefully do
          Bone.api.keys filter
        end
      end
      
      def key?(name)
        carefully do
          Bone.api.key? name
        end
      end
      
    end
    
    module Helpers
      def path(*parts)
        "/#{APIVERSION}/" << parts.flatten.join('/')
      end
    end
    include Bone::API::Helpers
    
    module HTTP
      include HTTParty
      base_uri Bone.source.to_s
      class << self 
        # /v2/[name]
        def get(name, query={})
          debug_output $stderr if Bone.debug
          super(Bone::API.path(name), :query => query)
        end
        def connect
        end
      end
      Bone.register_api :http, self
    end
    
    module Redis
      extend self
      attr_accessor :redis
      def get(name)
        redis.get rediskey(name)
      end
      def set(name, value)
        redis.set rediskey(name),  value
      end
      def keys(filter='*')
        redis.keys rediskey(filter)
      end
      def key?(name)
        redis.exists rediskey(name)
      end
      def connect
        require 'redis'
        require 'uri/redis'
        self.redis = ::Redis.connect(:url => Bone.source.to_s)
      end
      def rediskey(name)
        [APIVERSION, 'bone', name, 'value'].join(':')
      end
      Bone.register_api :redis, self
    end
    
    module Memory
      extend self
      @data = {}
      def get(name)
        @data[name.to_s]
      end
      def set(name, value)
        @data[name.to_s] = value.to_s
      end
      def keys
        @data.keys
      end
      def key?(name)
        @data.has_key?(name.to_s)
      end
      def connect
      end
      Bone.register_api :memory, self
    end
    
  end
  
  extend Bone::API::ClassMethods
  select_api
end