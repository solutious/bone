
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
      @version ||= YAML.load_file(File.join(BONE_HOME, 'VERSION.yml'))
    end
  end
end


class Bone
  unless defined?(Bone::APIVERSION)
    APIVERSION = 'v2'.freeze 
    SECRETCHAR = [('a'..'z'),('A'..'Z'),(0..9)].map(&:to_a).flatten.freeze
  end
  @source = URI.parse(ENV['BONE_SOURCE'] || 'redis://127.0.0.1:6379/')
  @apis = {}
  @digest_type = OpenSSL::Digest::SHA256
  class Problem < RuntimeError; end
  class NoToken < Problem; end  
  class << self
    attr_accessor :debug
    attr_reader :apis, :api, :source, :digest_type
    attr_writer :token, :secret
    
    def source= v
      @source = URI.parse v
      select_api
    end
    alias_method :src=, :source=
    alias_method :src, :source
    
    # e.g.
    #
    #  Bone.cred = 'token:secret'
    #
    def credentials= token
      @token, @secret = *token.split(':')
    end
    alias_method :cred=, :credentials=
    
    def token
      @token || ENV['BONE_TOKEN']
    end
    
    def secret 
      @secret || ENV['BONE_SECRET']
    end
    
    def info *msg
      STDERR.puts *msg
    end
    
    def ld *msg
      info *msg if debug
    end
    
    # Stolen from Rack::Utils which stole it from Camping.
    def uri_escape s
      s.to_s.gsub(/([^ a-zA-Z0-9_.-]+)/n) {
        '%'+$1.unpack('H2'*bytesize($1)).join('%').upcase
      }.tr(' ', '+')
    end
    
    # Stolen from Rack::Utils which stole it from Camping.
    def uri_unescape s
      s.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n){
        [$1.delete('%')].pack('H*')
      }
    end
    
    # Return the bytesize of String; uses String#size under Ruby 1.8 and
    # String#bytesize under 1.9.
    if ''.respond_to?(:bytesize)
      def bytesize s
        s.bytesize
      end
    else
      def bytesize s
        s.size
      end
    end
    
    def is_sha1? val
      val.to_s.match /\A[0-9a-f]{40}\z/
    end

    def is_sha256? val
      val.to_s.match /\A[0-9a-f]{64}\z/
    end

    def digest val, type=nil
      type ||= @digest_type
      type.hexdigest val
    end
    
    def random_token
      p1 = (0...21).map{ SECRETCHAR[rand(SECRETCHAR.length)] }.join
      p2 = Bone.api.token_suffix
      p3 = (0...2).map{ SECRETCHAR[rand(SECRETCHAR.length)] }.join
      [p1,p2,p3].join.upcase
    end
    
    def random_secret 
      src = [SECRETCHAR, %w'* ^ $ ! / . - _ + %'].flatten
      p1 = (0...2).map{ SECRETCHAR[rand(SECRETCHAR.length)] }.join
      p2 = (0...60).map{ src[rand(src.length)] }.join
      p3 = (0...2).map{ SECRETCHAR[rand(SECRETCHAR.length)] }.join      
      [p1,p2,p3].join
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
    
    def register_api scheme, klass
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
    def require_vendor name, version
      path = File.join(BONE_HOME, 'vendor', "#{name}-#{version}", 'lib')
      $:.unshift path
      Bone.ld "REQUIRE VENDOR: ", path
      require name
    end
  end
  
  require 'bone/api'
  include Bone::API::InstanceMethods
  extend Bone::API::ClassMethods
  select_api
end


