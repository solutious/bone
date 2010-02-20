@spec = Gem::Specification.new do |s|
  s.name = "bone"
  s.rubyforge_project = 'bone'
  s.version = "0.2.6"
  s.summary = "Get Bones"
  s.description = s.summary
  s.author = "Delano Mandelbaum"
  s.email = "delano@solutious.com"
  s.homepage = "http://github.com/solutious/bone"
  
  s.extra_rdoc_files = %w[README.md LICENSE.txt CHANGES.txt]
  s.has_rdoc = true
  s.rdoc_options = ["--line-numbers", "--title", s.summary, "--main", "README.md"]
  s.require_paths = %w[lib]
  
  s.executables = %w[bone]
  
  # = MANIFEST =
  # git ls-files
  s.files = %w(
  CHANGES.txt
  LICENSE.txt
  README.md
  Rakefile
  Rudyfile
  bin/bone
  bone.gemspec
  lib/bone.rb
  lib/bone/cli.rb
  try/bone.rb
  vendor/drydock-0.6.8/CHANGES.txt
  vendor/drydock-0.6.8/LICENSE.txt
  vendor/drydock-0.6.8/README.rdoc
  vendor/drydock-0.6.8/Rakefile
  vendor/drydock-0.6.8/bin/example
  vendor/drydock-0.6.8/drydock.gemspec
  vendor/drydock-0.6.8/lib/drydock.rb
  vendor/drydock-0.6.8/lib/drydock/console.rb
  vendor/drydock-0.6.8/lib/drydock/mixins.rb
  vendor/drydock-0.6.8/lib/drydock/mixins/object.rb
  vendor/drydock-0.6.8/lib/drydock/mixins/string.rb
  vendor/drydock-0.6.8/lib/drydock/screen.rb
  )

  
end
