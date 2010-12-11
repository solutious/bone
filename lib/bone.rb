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
  
  class << self
    attr_accessor :debug
    
    def ld *msg
      STDERR.puts *msg if debug
    end
    
    def get(name)
      carefully do
        Bone::API.get name
      end
    end
    
    def carefully
      begin
        Bone::API.debug_output $stderr if Bone.debug
        yield
      rescue => ex
        Bone.ld "#{ex.class}: #{ex.message}", ex.backtrace
        nil
      end
    end
    
    alias_method :[], :get
    
  end
  
  module API
    include HTTParty
    
    base_uri ENV['BONE_SOURCE'] || 'https://api.bonery.com'
    
    class << self 
      
      def get(name, query={})
        super(path(APIVERSION, name), :query => query)
      end
      
      private 
      def path(*parts)
        '/' << parts.flatten.join('/')
      end
    end
    
  end
  
end