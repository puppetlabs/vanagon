source ENV['GEM_SOURCE'] || "https://rubygems.org"

def lock_manager_location_for(place)
  if place =~ /^(git[:@][^#]*)#(.*)/
    [{ git: $1, branch: $2, require: false }]
  elsif place =~ /^file:\/\/(.*)/
    ['>= 0', { path: File.expand_path($1), require: false }]
  else
    [place, { require: false }]
  end
end

# Accommodate dependencies from the Vanagon Gemspec
gemspec

# Confine EC2 engine dependencies
group "ec2-engine" do
  gem "aws-sdk", "~> 2.2.0", require: false
end

# "lock_manager" is specified in development dependencies, to allow
# the use of unreleased versions of "lock_manager" during development.
group(:development, :test) do
  gem 'json'
  gem 'lock_manager', *lock_manager_location_for(ENV['LOCK_MANAGER_LOCATION'] || '>= 0')
  gem 'packaging', '~> 0.4.0', github: 'puppetlabs/packaging', branch: 'master'
  gem 'rake'
  gem 'rspec', '~> 3.0', require: false
  gem 'rubocop', "~> 0.41.2", require: false
  gem 'yard', require: false
end
