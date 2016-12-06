require 'time'

Gem::Specification.new do |gem|
  gem.name    = 'vanagon'
  gem.version = %x(git describe --tags).gsub('-', '.').chomp
  gem.date    = Date.today.to_s

  gem.summary = "All of your packages will fit into this van with this one simple trick."
  gem.description = "Vanagon is a tool to build a single package out of a project, which can itself contain one or more components."
  gem.license = "Apache-2.0"

  gem.authors  = ['Puppet Labs']
  gem.email    = 'info@puppet.com'
  gem.homepage = 'http://github.com/puppetlabs/vanagon'
  gem.specification_version = 3
  gem.required_ruby_version = '~> 2.1'

  # Handle git repos responsibly
  gem.add_runtime_dependency('git', '~> 1.3.0')
  # Parse scp-style triplets like URIs; used for Git source handling.
  gem.add_runtime_dependency('fustigit', '~> 0.1.3')
  # Handle locking hardware resources
  gem.add_runtime_dependency('lock_manager', '>= 0')
  gem.require_path = 'lib'
  gem.bindir       = 'bin'
  gem.executables  = ['build', 'inspect', 'ship', 'repo', 'devkit', 'build_host_info', 'build_component_tarballs']

  # Ensure the gem is built out of versioned files
  gem.files = Dir['{bin,lib,spec,resources}/**/*', 'README*', 'LICENSE*'] & `git ls-files -z`.split("\0")
  gem.test_files = Dir['spec/**/*_spec.rb']
end
