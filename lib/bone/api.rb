
class Bone
  module API
    module InstanceMethods
      attr_accessor :token, :secret
      def initialize(t, s=nil)
        # TODO: Add size command
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
          Bone.api.keys(token, secret, filter) || []
        end
      end
      def key?(name)
        carefully do
          raise_errors
          Bone.api.key? token, secret, name
        end
      end
      def register(this_token, this_secret)
        carefully do
          Bone.api.register this_token, this_secret
        end
      end
      def generate
        carefully do
          Bone.api.generate || []
        end
      end
      def destroy(token)
        carefully do
          Bone.api.destroy token, secret
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
        rescue Errno::ECONNREFUSED => ex
          Bone.info ex.message
          nil
        rescue => ex
          Bone.ld "#{ex.class}: #{ex.message}", ex.backtrace
          nil
        end
      end
    end
    module ClassMethods
      def get(name)
        new(Bone.token, Bone.secret).get name
      end
      alias_method :[], :get
      def set(name, value)
        new(Bone.token, Bone.secret).set name, value
      end
      alias_method :[]=, :set
      def keys(filter='*')
        new(Bone.token, Bone.secret).keys filter
      end
      def key?(name)
        new(Bone.token, Bone.secret).key? name
      end
      def register(this_token, this_secret)
        new(Bone.token, Bone.secret).register this_token, this_secret
      end
      def generate
        new(Bone.token, Bone.secret).generate
      end
      def destroy(token)
        new(Bone.token, Bone.secret).destroy token
      end
      def token?(token)
        new(Bone.token, Bone.secret).token? token
      end
    end
    module Helpers
      def path(*parts)
        "/#{APIVERSION}/" << parts.flatten.collect { |v| Bone.uri_escape(v) }.join('/')
      end
      def prefix(*parts)
        parts.flatten!
        parts.unshift *[APIVERSION, 'bone']
        parts.join(':')
      end
    end
    extend Bone::API::Helpers
  end

  module API
  
    module HTTP
      SIGVERSION = 'v2'.freeze unless defined?(Bone::API::HTTP::SIGVERSION)
      @token_suffix = 2.freeze
      class << self 
        attr_reader :token_suffix
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
          ret = http_request token, secret, :get, path, {}
          (ret || '').split($/)
        end
        def key?(token, secret, name)
          !get(token, secret, name).nil?
        end
        def destroy(token, secret)
          query = {}
          path = Bone::API.path('destroy', token)
          ret = http_request token, secret, :delete, path, query
          !ret.nil?  # errors return nil
        end
        def secret(token, secret)
          path = Bone::API.path(token, 'secret')
          ret = http_request token, secret, :get, path, {}
        end
        def register(token, secret)
          query = {}
          path = Bone::API.path('register', token)
          http_request token, secret, :post, path, query, secret
        end
        def generate
          path = Bone::API.path('generate')
          ret = http_request '', '', :post, path, {}
          ret.nil? ? nil : ret.split($/)
        end
        def token?(token, secret)
          path = Bone::API.path(token)
          query = {}
          ret = http_request token, secret, :get, path, query
          !ret.nil?
        end
        def connect
          require 'em-http-request'  # TODO: catch error, deregister this API
          @external_em = EM.reactor_running?
          #@retry_delay, @redirects, @max_retries, @performed_retries = 2, 1, 2, 0
        end
        
        def canonical_time now=Time.now
          now.utc.to_i
        end
        
        def canonical_host host
          if URI === host
            host.port ||= 80
            host = [host.host.to_s, host.port.to_s].join(':')
          end
          host.downcase
        end
        
        # Based on / stolen from: https://github.com/chneukirchen/rack/blob/master/lib/rack/utils.rb
        # which was based on / stolen from Mongrel
        def parse_query(qs, d = '&;')
          params = {}
          (qs || '').split(/[#{d}] */n).each do |p|
            k, v = p.split('=', 2).map { |x| Bone.uri_unescape(x) }
            if cur = params[k]
              if cur.class == Array
                params[k] << v
              else
                params[k] = [cur, v]
              end
            else
              params[k] = v
            end
          end
          return params
        end
            
        # Builds the canonical string for signing requests. This strips out all '&', '?', and '='
        # from the query string to be signed.  The parameters in the path passed in must already
        # be sorted in case-insensitive alphabetical order and must not be url encoded.
        #
        # Based on / stolen from: https://github.com/grempe/amazon-ec2/blob/master/lib/AWS.rb
        # 
        # See also: http://docs.amazonwebservices.com/AWSEC2/2009-04-04/DeveloperGuide/index.html?using-query-api.html
        #
        def canonical_sig_string host, meth, path, query, body=nil
          # Sort, and encode parameters into a canonical string.
          sorted_params = query.sort {|x,y| x[0].to_s <=> y[0].to_s }
          encoded_params = sorted_params.collect do |p|
            encoded = [Bone.uri_escape(p[0]), Bone.uri_escape(p[1])].join '='
            # Ensure spaces are encoded as '%20', not '+'
            encoded = encoded.gsub '+', '%20'
            # According to RFC3986 (the scheme for values expected 
            # by signing requests), '~' should not be encoded
            encoded = encoded.gsub '%7E', '~'
          end
          querystr = encoded_params.join '&'
          parts = [meth.to_s.downcase, canonical_host(host), path, querystr]
          parts << body unless body.to_s.empty?
          parts.join "\n"
        end
      
        # Encodes the given string with the secret_access_key by taking the
        # hmac-sha1 sum, and then base64 encoding it.  Optionally, it will also
        # url encode the result of that to protect the string if it's going to
        # be used as a query string parameter.
        #
        # Based on / stolen from: https://github.com/grempe/amazon-ec2/blob/master/lib/AWS.rb
        def encode secret, str, escape=true
          digest = OpenSSL::HMAC.digest Bone.digest_type.new, secret.to_s, str.to_s
          b64_hmac = Base64.encode64(digest).tr "\n", ''
          escape ? Bone.uri_escape(b64_hmac) : b64_hmac
        end
      
        def prepare_query query={}, token=Bone.token, stamp=canonical_time
          { "sigversion" => Bone::API::HTTP::SIGVERSION,
            "apiversion" => Bone::APIVERSION,
            "token"      => token,
            "stamp"      => stamp
          }.merge query
        end
        
        def sign_query token, secret, meth, path, query, body=nil
          sig = generate_signature secret, Bone.source, meth, path, query, body
          { 'sig' => sig }.merge query
        end
        
        # Based on / stolen from: https://github.com/grempe/amazon-ec2/blob/master/lib/AWS.rb
        def generate_signature secret, host, meth, path, query, body=nil
          str = canonical_sig_string host, meth, path, query, body
          sig = encode secret, str
          Bone.ld [sig, str, body].inspect
          sig
        end
        
        private
      
        # based on: https://github.com/EmmanuelOga/firering/blob/master/lib/firering/connection.rb
        def http_request token, secret, meth, path, query={}, body=nil
          uri = Bone.source.clone
          uri.path = path
          query = prepare_query query, token
          signed_query = sign_query token, secret, meth, path, query, body
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
      
        def em_request meth, uri, query, body, &blk
          args = { :query => query, :timeout => 10 }
          args[:head] = {}
          args[:body] = body.to_s unless body.nil?
          http = EventMachine::HttpRequest.new(uri).send(meth, args)
          http.errback do
            #perform_retry(http) do
            #  http(method, path, data, &callback)
            #end
            Bone.info "Could not access #{uri}"
            EventMachine.stop @external_em 
          end
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
      @token_suffix = 1.freeze
      class << self
        attr_reader :token_suffix
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
        def destroy(token, secret)
          Token.tokens.delete token
          Token.new(token).secret.destroy!
        end
        def register(token, secret)
          raise RuntimeError, "Could not generate token" if token.nil? || token?(token)
          Token.tokens.add Time.now.utc.to_i, token
          t = Token.new(token).secret = secret
          token
        end
        def generate
          begin 
            token = Bone.random_token
            attempts ||= 10
          end while token?(token) && !(attempts -= 1).zero?
          secret = Bone.random_secret
          raise RuntimeError, "Could not generate token" if token.nil? || token?(token)
          Token.tokens.add Time.now.utc.to_i, token
          t = Token.new(token).secret = secret
          [token, secret]
        end
        def secret token
          Token.new(token).secret.value
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
      end
      Bone.register_api :redis, self
    end
  
    module Memory
      extend self
      @token_suffix = 0.freeze
      attr_reader :token_suffix
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
      def destroy(token, secret)
        @tokens.delete token
      end
      def register(token, secret)
        raise RuntimeError, "Could not generate token" if token.nil? || token?(token)
        @tokens[token] = secret
        token
      end
      def secret(token)
        @tokens[token]
      end
      def generate
        begin 
          token = Bone.random_token 
          attemps ||= 10
        end while token?(token) && !(attempts -= 1).zero?
        secret = Bone.random_secret
        @tokens[token] = secret
        [token, secret]
      end
      def token?(token, secret=nil)
        @tokens.key?(token)
      end
      def connect
      end
      Bone.register_api :memory, self
    end
  
  end
end