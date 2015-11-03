require 'time'

Gem::Specification.new do |gem|
  gem.name    = 'vanagon'
  gem.version = %x(git describe --tags).gsub('-', '.').chomp
  gem.date    = Date.today.to_s

  gem.summary = "All of your packages will fit into this van with this one simple trick."
  gem.description = "Vanagon is a tool to build a single package out of a project, which can itself contain one or more components."
  gem.license = "Apache-2.0"

  gem.authors  = ['Puppet Labs']
  gem.email    = 'info@puppetlabs.com'
  gem.homepage = 'http://github.com/puppetlabs/vanagon'
  gem.specification_version = 3
  gem.required_ruby_version = '~> 2.1.0'

  gem.add_development_dependency('rspec', ["~> 3.0"])
  gem.add_development_dependency('yard', '~> 0.8')
  gem.require_path = 'lib'
  gem.bindir       = 'bin'
  gem.executables  = ['build', 'ship', 'repo', 'devkit']

  # Ensure the gem is built out of versioned files
  gem.files = Dir['{bin,lib,spec,templates}/**/*', 'README*', 'LICENSE*'] & `git ls-files -z`.split("\0")
  gem.test_files = Dir['spec/**/*_spec.rb']
end
