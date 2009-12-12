# ruby -rubygems -Ilib try/bone.rb
require 'bone'

ENV['BONE_TOKEN'] = '1c397d204aa4e94f566d7f78cc4bb5bef5b558d9bd64c1d8a45e67a621fb87dc'

Bone['poop'] = rand
puts Bone['poop']
