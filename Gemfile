source ENV['GEM_SOURCE'] || "https://rubygems.org"

def location_for(place)
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
  gem 'fakefs'
  gem 'json'
  gem 'lock_manager', *location_for(ENV['LOCK_MANAGER_LOCATION'] || '>= 0')
  gem 'packaging', *location_for(ENV['PACKAGING_LOCATION'] || '~> 0.99')
  gem 'rake', require: false
  gem 'rspec', '~> 3.0', require: false
  gem 'rubocop', "~> 0.81.0", require: false
  gem 'simplecov', require: false
  gem 'yard', require: false
end
