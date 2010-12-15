
sources = ['redis://localhost:8045', 'http://localhost:3073/']
execs = ['/usr/bin/ruby', '/usr/local/bin/ruby']

def run_command *args
  cmd = '%s -rubygems %s %s' % args
  ret, status = `#{cmd}`, $?.exitstatus
  puts cmd, "(#{status}) #{ret}", $/
  [status, ret]
end

sources.each do |source|
  ENV['BONE_SOURCE'] = source
  puts '-' * 20, source, '-' * 20
  execs.each do |ruby|
    status, token = *run_command(ruby, 'bin/bone', :generate)
    next unless status.zero?
    ENV['BONE_TOKEN'] = token
    status, ret = *run_command(ruby, 'bin/bone', :token)
    next unless token == ret
    p 1
    break
  end
end