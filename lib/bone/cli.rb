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
    if File.exists?(@argv[1]) && !@option.string
      @argv[1] = File.readlines(@argv[1]).join
      opts[:file] = true
    end
    puts Bone.set(@argv[0], @argv[1], opts)
  end
  
  def keys
    puts Bone.keys @argv[0]
  end
  
end
