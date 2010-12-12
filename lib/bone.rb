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
  
  class << self
    attr_accessor :debug
    attr_reader :source, :api
    
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
    
    # /v2/[name]
    def get(name)
      carefully do
        Bone.api.get name
      end
    end
    alias_method :[], :get
    
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
        case Bone.source.scheme
        when 'redis'
          @api = Bone::API::Redis
        when 'http'
          @api = Bone::API::HTTP
        else
          raise RuntimeError, "Bad source: #{Bone.source}"
        end
      rescue => ex
        Bone.info Bone.source, "#{ex.class}: #{ex.message}", ex.backtrace
        exit
      end
    end
  end
  
  module API
    class << self
      def path(*parts)
        "/#{APIVERSION}/" << parts.flatten.join('/')
      end
    end
    
    module HTTP
      include HTTParty
      base_uri Bone.source.to_s
      class << self 
        def get(name, query={})
          debug_output $stderr if Bone.debug
          super(Bone::API.path(name), :query => query)
        end
      end
    end
    
    module Redis
      module InstanceMethods
      end
    end
    
  end
  
  select_api
end