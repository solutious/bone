require 'bone'
require 'net/http'

class Bone::CLI < Drydock::Command
  
  def check!
    @token = @global.token || ENV['BONE_TOKEN']
    raise Bone::NoToken, @token unless Bone.token?(@token)
    Bone.token = @token
  end
  
  def get
    check!
    @argv.unshift @alias unless @alias == 'get'
    raise "No key specified" unless @argv.first
    ret = Bone.get(@argv.first)
    puts ret unless ret.nil? 
  end
  
  def del
    check!
    raise "No key specified" unless @argv.first
    puts Bone.delete(@argv.first)
  end
  
  def set
    check!
    opts = {:token => @token }
    name, value = *(@argv.size == 1 ? @argv.first.split('=') : @argv)
    raise "No key specified" unless name
    raise "No value specified" unless value
    if File.exists?(value) && !@option.string
      value = File.readlines(value).join
      opts[:file] = true
    end
    puts Bone[name] = value
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
    puts Bone.token
  end
  
  def generate
    puts Bone.generate_token(:tmp)
  #rescue Bone::NoToken => ex
  #  update_token_dialog
  #  exit 1
  end
  
  private 
  def update_token_dialog
    newtoken = Bone.generate_token
    puts newtoken and return if @global.quiet
    puts "Set the BONE_TOKEN environment variable with the following value"
    puts newtoken
  end
  
end
