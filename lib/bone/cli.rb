require 'bone'

# TODO: finish this

class Bone::CLI < Drydock::Command
  
  def check!
    @token = @global.token || ENV['BONE_TOKEN']
    raise Bone::NoToken, @token unless Bone.token?(@token)
    Bone.token = @token
  end
  
  def get
    check!
    @argv.unshift @alias unless @alias == 'get'
    ## TODO: handle bone name=value
    ##if @alias.index('=') > 0
    ##  a = @alias.gsub(/\s+=\s+/, '=')
    ##  name, value = *( ? @argv.first.split('=') : @argv)
    ##end
    raise Bone::Problem, "No key specified" unless @argv.first
    ret = Bone.get(@argv.first)
    puts ret unless ret.nil? 
  end
  
  def set
    # TODO: use STDIN instead of @option.string
    check!
    name, value = *(@argv.size == 1 ? @argv.first.split('=') : @argv)
    raise Bone::Problem, "No key specified" unless name
    from_stdin = false
    if value.nil? && !stdin.tty? && !stdin.eof?
      from_stdin = true
      value = stdin.read
    end
    raise Bone::Problem, "Cannot set null value" unless value
    Bone[name] = value
    puts from_stdin ? '<STDIN>' : value
  end
  
  #def del
  #  check!
  #  raise Bone::Problem, "No key specified" unless @argv.first
  #  puts Bone.delete(@argv.first)
  #end
  
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

  def secret
    check!
    puts Bone.secret
  end
  
  def generate
    puts "Your token has been generated:"
    t, s = *Bone.generate
    puts "BONE_TOKEN=#{t}"
    puts "BONE_SECRET=#{s}"
  #rescue Bone::NoToken => ex
  #  update_token_dialog
  #  exit 1
  end
  
  private 
  
end
