Gem::Specification.new do |gem|
  gem.name    = 'vanagon'
  gem.version = %x(git describe --tags).gsub('-', '.').chomp
  gem.date    = Date.today.to_s

  gem.summary = "Another mega-package build tool, now with more Make"
  gem.description = "Vanagon is a tool to build a single package out of a project, which can itself contain one or more components."

  gem.authors  = ['Puppet Labs']
  gem.email    = 'info@puppetlabs.com'
  gem.homepage = 'http://github.com/puppetlabs/vanagon'

  gem.add_development_dependency('rspec', ["~> 3.0"])
  gem.add_development_dependency('yard')
  gem.require_path = 'lib'
  gem.bindir       = 'bin'
  gem.executables  = ['build', 'ship', 'repo']

  # Ensure the gem is built out of versioned files
  gem.files = Dir['{bin,lib,spec,templates}/**/*', 'README*', 'LICENSE*'] & `git ls-files -z`.split("\0")
  gem.test_files = Dir['spec/**/*_spec.rb']
end
