require 'bone'
require 'net/http'

class Bone::CLI < Drydock::Command
  
  def get
    @argv.unshift @alias unless @alias == 'get'
    #puts "KEYS: " << @argv.inspect
    puts Bone.get(@argv.first)
  end
  
  def set
    opts = {}
    keyname, value = *(@argv.size == 1 ? @argv.first.split('=') : @argv)
    if File.exists?(value) && !@option.string
      value = File.readlines(value).join
      opts[:file] = true
    end
    puts Bone.set(keyname, value, opts)
  end
  
  def keys
    puts Bone.keys @argv[0]
  end
  
end
