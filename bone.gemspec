@spec = Gem::Specification.new do |s|
  s.name = "bone"
  s.rubyforge_project = 'bone'
  s.version = "0.1.0"
  s.summary = "Get Bones"
  s.description = s.summary
  s.author = "Delano Mandelbaum"
  s.email = "delano@solutious.com"
  s.homepage = ""
  
  s.extra_rdoc_files = %w[README.md LICENSE.txt CHANGES.txt]
  s.has_rdoc = true
  s.rdoc_options = ["--line-numbers", "--title", s.summary, "--main", "README.rdoc"]
  s.require_paths = %w[lib]
  
  s.executables = %w[bone]
  
  # = MANIFEST =
  # git ls-files
  s.files = %w(
  
  )

  
end
