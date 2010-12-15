
unless defined?(BONE_HOME)
  BONE_HOME = File.expand_path(File.join(File.dirname(__FILE__), '..') )
end

local_libs = %w{familia}
local_libs.each { |dir| 
  a = File.join(BONE_HOME, '..', '..', 'opensource', dir, 'lib')
  $:.unshift a
}

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
      
      def register_token(token, secret)
        carefully do
          Bone.api.register_token token, secret
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
      def prefix(*parts)
        parts.flatten!
        parts.unshift *[APIVERSION, 'bone']
        parts.join(':')
      end
    end
    extend Bone::API::Helpers
    
    module HTTP
      class << self 
        # /v2/[name]
        def get(token, name)
          path = Bone::API.path(token, 'key', name)
          query = {}
          http_request :get, path, query
        end
        def set(token, name, value)
          path = Bone::API.path(token, 'key', name)
          query = {}
          http_request :post, path, query, value
        end
        def keys(token, filter='*')
          path = Bone::API.path(token, 'keys')
          ret = http_request :get, path, {} || []
          ret.split $/
        end
        def key?(token, name)
          !get(token, name).nil?
        end
        def destroy_token(token)
          query = {}
          path = Bone::API.path('destroy', token)
          http_request :delete, path, query, 'secret'
        end
        def register_token(token, secret)
          query = {}
          path = Bone::API.path('register', token)
          http_request :post, path, query, secret
        end
        def generate_token(secret)
          path = Bone::API.path('generate')
          http_request :post, path, {}, secret
        end
        def token?(token)
          path = Bone::API.path(token)
          query = {}
          ret = http_request :get, path, query
          !ret.nil?
        end
        def connect
          require 'em-http-request'
          @external_em = EM.reactor_running?
          #@retry_delay, @redirects, @max_retries, @performed_retries = 2, 1, 2, 0
        end
        
        private 
        
        # based on: https://github.com/EmmanuelOga/firering/blob/master/lib/firering/connection.rb
        def http_request meth, path, query={}, body=nil
          uri = Bone.source.clone
          uri.path = path
          Bone.ld "#{meth} #{uri} (#{query})"
          content, status, headers = nil
          handler = Proc.new do |http|
            content, status, headers = http.response, http.response_header.status, http.response_header
          end
          if @external_em
            http_request_proc meth, uri, query, body, &handler
          else
            EM.run {
              http_request_proc meth, uri, query, body, &handler
            }
          end
          if status >= 400
            Bone.ld "Request failed: #{status} #{content}"
            nil
          else
            content
          end
        end
        
        def http_request_proc method, uri, query, body, &blk
          args = { :query => query, :timeout => 10 }
          args[:body] = body.to_s unless body.nil?
          http = EventMachine::HttpRequest.new(uri).send(method, args)
          #http.errback do
          #  perform_retry(http) do
          #    http(method, path, data, &callback)
          #  end
          #  EventMachine.stop
          #end
          http.callback {
            Bone.ld "#{http.response_header.status}: #{http.response_header.inspect}"
            #reset_retries_counter
            blk.call(http) if blk
            EventMachine.stop unless @external_em
          }
          http
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
      def register_token(token, secret)
        raise RuntimeError, "Could not generate token" if token.nil? || token?(token)
        Token.tokens.add Time.now.utc.to_i, token
        t = Token.new(token).secret = secret
        token
      end
      def generate_token(secret)
        begin 
          token = Bone.random_digest
          attempts ||= 10
        end while token?(token) && !(attempts -= 1).zero?
        raise RuntimeError, "Could not generate token" if token.nil? || token?(token)
        Token.tokens.add Time.now.utc.to_i, token
        t = Token.new(token).secret = secret
        token
      end
      def token?(token)
        Token.tokens.member?(token.to_s)
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
          @token, @name, @bucket = token.to_s, name.to_s, bucket.to_s
          initialize_redis_objects
        end
        def index
          [token, bucket, name].join ':'
        end
      end
      class Token
        include Familia
        prefix Bone::API.prefix(:token)
        string :secret
        zset :keys
        class_zset :tokens
        index :token
        attr_reader :token
        def initialize(token)
          @token = token.to_s
          initialize_redis_objects
        end
      end
      Bone.register_api :redis, self
    end
    
    module Memory
      extend self
      @data, @tokens = {}, {}
      def get(token, name)
        @data[Bone::API.prefix(token, name)]
      end
      def set(token, name, value)
        @data[Bone::API.prefix(token, name)] = value.to_s
      end
      def keys(token, filter='*')
        filter = '.+' if filter == '*'
        filter = Bone::API.prefix(token, filter)
        @data.keys.select { |name| name =~ /#{filter}/ }
      end
      def key?(token, name)
        @data.has_key?(Bone::API.prefix(token, name))
      end
      def destroy_token(token)
        @tokens.delete token
      end
      def register_token(token, secret)
        raise RuntimeError, "Could not generate token" if token.nil? || token?(token)
        @tokens[token] = secret
        token
      end
      def generate_token(secret)
        begin 
          token = Bone.random_digest
          attemps ||= 10
        end while token?(token) && !(attempts -= 1).zero?
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


