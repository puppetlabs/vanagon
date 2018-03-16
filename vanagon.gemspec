require 'time'

Gem::Specification.new do |gem|
  gem.name    = 'vanagon'
  gem.version = %x(git describe --tags).tr('-', '.').chomp
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
  # - MIT licensed: https://rubygems.org/gems/git
  gem.add_runtime_dependency('git', '~> 1.3.0')
  # Parse scp-style triplets like URIs; used for Git source handling.
  # - MIT licensed: https://rubygems.org/gems/fustigit
  gem.add_runtime_dependency('fustigit', '~> 0.1.3')
  # Handle locking hardware resources
  # - ASL v2 licensed: https://rubygems.org/gems/lock_manager
  gem.add_runtime_dependency('lock_manager', '>= 0')
  # Utilities for `ship` and `repo` commands
  # - ASL v2 licensed: https://rubygems.org/gems/packaging
  gem.add_runtime_dependency('packaging')
  gem.require_path = 'lib'
  gem.bindir       = 'bin'
  gem.executables  = %w[build inspect ship render repo sign build_host_info]

  # Ensure the gem is built out of versioned files
  gem.files = Dir['{bin,lib,spec,resources}/**/*', 'README*', 'LICENSE*'] & %x(git ls-files -z).split("\0")
  gem.test_files = Dir['spec/**/*_spec.rb']
end
