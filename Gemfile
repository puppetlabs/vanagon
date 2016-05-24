source ENV['GEM_SOURCE'] || "https://rubygems.org"

def lock_manager_location_for(place)
  if place =~ /^(git[:@][^#]*)#(.*)/
    [{ :git => $1, :branch => $2, :require => false }]
  elsif place =~ /^file:\/\/(.*)/
    ['>= 0', { :path => File.expand_path($1), :require => false }]
  else
    [place, { :require => false }]
  end
end

group "ec2-engine" do
  gem "aws-sdk", "~> 2.2.0", :require => false
end

group(:development, :test) do
  gem 'rspec', '~> 3.0', :require => false
  gem 'yard', :require => false
  gem 'packaging', '~> 0.4.0', :github => 'puppetlabs/packaging', :branch => 'master'
  gem 'rubocop', "~> 0.26.1"
  gem 'json'
  gem 'lock_manager', *lock_manager_location_for(ENV['LOCK_MANAGER_LOCATION'] || '>= 0')
end
