require 'bone'
require 'net/http'

class Bone::CLI < Drydock::Command
  
  def get
    @argv.unshift @alias unless @alias == 'get'
    #puts "KEYS: " << @argv.inspect
    puts Bone.get(Bone::CID, @argv.first)
  end
  
  def set
    #puts "KEYS: " << @argv.inspect
    puts Bone.set(Bone::CID, @argv[0], @argv[1])
  end
  
end
