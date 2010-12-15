

module Bone::API
  
  module HTTP
    SIGVERSION = 'v1'.freeze unless defined?(Bone::API::HTTP::SIGVERSION)
    
    class << self 
      # /v2/[name]
      def get(token, secret, name)
        path = Bone::API.path(token, 'key', name)
        query = {}
        http_request token, secret, :get, path, query
      end
      def set(token, secret, name, value)
        path = Bone::API.path(token, 'key', name)
        query = {}
        http_request token, secret, :post, path, query, value
      end
      def keys(token, secret, filter='*')
        path = Bone::API.path(token, 'keys')
        ret = http_request token, secret, :get, path, {} || []
        ret.split $/
      end
      def key?(token, secret, name)
        !get(token, secret, name).nil?
      end
      def destroy_token(token, secret)
        query = {}
        path = Bone::API.path('destroy', token)
        http_request token, secret, :delete, path, query, 'secret'
      end
      def register_token(token, secret)
        query = {}
        path = Bone::API.path('register', token)
        http_request token, secret, :post, path, query
      end
      def generate_token(secret)
        path = Bone::API.path('generate')
        http_request '', secret, :post, path, {}
      end
      def token?(token, secret)
        path = Bone::API.path(token)
        query = {}
        ret = http_request token, secret, :get, path, query
        !ret.nil?
      end
      def connect
        require 'em-http-request'
        @external_em = EM.reactor_running?
        #@retry_delay, @redirects, @max_retries, @performed_retries = 2, 1, 2, 0
      end
      
      def sign_query token, secret, meth, path, query
        sig = generate_signature secret, Bone.source.host, meth, path, query
        { 'sig' => sig }.merge query
      end
      
      # Based on / stolen from: https://github.com/grempe/amazon-ec2/blob/master/lib/AWS.rb
      def generate_signature secret, host, meth, path, query
        str = canonical_sig_string host, meth, path, query
        encode secret, str
      end
      
      def canonical_time now=Time.now
        now.utc.iso8601
      end
      
      # Builds the canonical string for signing requests. This strips out all '&', '?', and '='
      # from the query string to be signed.  The parameters in the path passed in must already
      # be sorted in case-insensitive alphabetical order and must not be url encoded.
      #
      # Based on / stolen from: https://github.com/grempe/amazon-ec2/blob/master/lib/AWS.rb
      def canonical_sig_string host, meth, path, query
        query = query.reject { |key, value| value.to_s.empty? }  # remove empties
        # Sort, and encode parameters into a canonical string.
        sorted_params = query.sort {|x,y| x[0].to_s <=> y[0].to_s }
        encoded_params = sorted_params.collect do |p|
          encoded = [Bone.uri_escape(p[0]), Bone.uri_escape(p[1])].join '='
          # Ensure spaces are encoded as '%20', not '+'
          encoded = encoded.gsub('+', '%20')
          # According to RFC3986 (the scheme for values expected by signing requests), '~' 
          # should not be encoded
          encoded = encoded.gsub('%7E', '~')
        end
        querystr = encoded_params.join '&'
        [meth, host, path, querystr].join "\n"
      end
      
      # Encodes the given string with the secret_access_key by taking the
      # hmac-sha1 sum, and then base64 encoding it.  Optionally, it will also
      # url encode the result of that to protect the string if it's going to
      # be used as a query string parameter.
      #
      # Based on / stolen from: https://github.com/grempe/amazon-ec2/blob/master/lib/AWS.rb
      def encode(secret, str, encode=true)
        digest_type = OpenSSL::Digest::Digest.new('sha256')
        digest = OpenSSL::HMAC.digest(digest_type, secret.to_s, str.to_s)
        b64_hmac = Base64.encode64(digest).gsub("\n","")
        encode ? Bone.uri_escape(b64_hmac) : b64_hmac
      end
      
      def prepare_query query={}, token=Bone.token, stamp=canonical_time
        { "sigversion" => SIGVERSION,
          "apiversion" => Bone::APIVERSION,
          "token"      => token,
          "stamp"      => stamp
        }.merge query
      end
      
      private
      
      # based on: https://github.com/EmmanuelOga/firering/blob/master/lib/firering/connection.rb
      def http_request token, secret, meth, path, query={}, body=nil
        uri = Bone.source.clone
        uri.path = path
        query = prepare_query query, token
        signed_query = sign_query token, secret, meth, path, query
        Bone.ld "#{meth} #{uri} (#{query})"
        content, status, headers = nil
        handler = Proc.new do |http|
          content, status, headers = http.response, http.response_header.status, http.response_header
        end
        if @external_em
          em_request meth, uri, signed_query, body, &handler
        else
          EM.run {
            em_request meth, uri, signed_query, body, &handler
          }
        end
        if status >= 400
          Bone.ld "Request failed: #{status} #{content}"
          nil
        else
          content
        end
      end
      
      def em_request method, uri, query, body, &blk
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
    def get(token, secret, name)
      Key.new(token, name).value.get   # get returns nil if not set
    end
    def set(token, secret, name, value)
      Key.new(token, name).value = value
      Token.new(token).keys.add Time.now.utc.to_f, name
      value.to_s
    end
    def keys(token, secret, filter='*')
      Token.new(token).keys.to_a
    end
    def key?(token, secret, name)
      Key.new(token, name).value.exists?
    end
    def destroy_token(token, secret)
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
    def token?(token, secret=nil)
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
    def get(token, secret, name)
      @data[Bone::API.prefix(token, name)]
    end
    def set(token, secret, name, value)
      @data[Bone::API.prefix(token, name)] = value.to_s
    end
    def keys(token, secret, filter='*')
      filter = '.+' if filter == '*'
      filter = Bone::API.prefix(token, filter)
      @data.keys.select { |name| name =~ /#{filter}/ }
    end
    def key?(token, secret, name)
      @data.has_key?(Bone::API.prefix(token, name))
    end
    def destroy_token(token, secret)
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
    def token?(token, secret=nil)
      @tokens.key?(token)
    end
    def connect
    end
    Bone.register_api :memory, self
  end
  
end