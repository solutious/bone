require 'bone'
require 'net/http'

class Bone::CLI < Drydock::Command
  
  def check!
    @token = @global.t || ENV['BONE_TOKEN']
    raise Bone::BadBone, @token unless Bone.valid_token?(@token)
  end
  
  def get
    check!
    @argv.unshift @alias unless @alias == 'get'
    raise "No key specified" unless @argv.first
    puts Bone.get(@argv.first)
  end
  
  def set
    check!
    opts = {:token => @token }
    keyname, value = *(@argv.size == 1 ? @argv.first.split('=') : @argv)
    raise "No key specified" unless keyname
    raise "No value specified" unless value
    if File.exists?(value) && !@option.string
      value = File.readlines(value).join
      opts[:file] = true
    end
    puts Bone.set(keyname, value, opts)
  end
  
  def keys
    check!
    list = Bone.keys(@argv[0])
    if list.empty? 
      return if @global.quiet
      puts "No keys" 
      puts "Try: bone set keyname=keyvalue"
    else
      puts list
    end
  end
  
  def token
    check!  
    if @option.force
      generate_token_dialog
    else
      puts @token
    end
  rescue Bone::BadBone => ex
    generate_token_dialog
    exit 1
  end
  
  private 
  def generate_token_dialog
    newtoken = Bone.generate_token
    puts newtoken and return if @global.quiet
    puts "Set the BONE_TOKEN environment variable with the following token"
    puts newtoken
  end
  
end
