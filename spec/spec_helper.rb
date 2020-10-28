# Coverage configuration should come ahead of everything else.
# This will ensure that code paths are followed appropriately.
if ENV["COVERAGE"]
  require 'simplecov'
  SimpleCov.start do
    add_filter '.bundle'
    add_filter 'spec'
    add_filter 'vendor'

    # Define a minimum coverage score, and fail if it's not met.
    # This should probably be a Float, not an Integer but as
    # long as it's not a String it's probably fine.
    #
    # The coverage score on 2017-02-07 for commit 770b67db was 71.85
    # - Ryan McKern, 2017-02-07
    minimum_coverage ENV['MINIMUM_SCORE'] || 70.00
  end
end

require 'tmpdir'
require 'vanagon'
require 'webmock/rspec'

RSpec.configure do |c|
  c.before do
    allow_any_instance_of(Vanagon::Component::Source::Git).to receive(:puts)
    allow_any_instance_of(Vanagon::Component::Source::Http).to receive(:puts)
    allow_any_instance_of(Vanagon::Component::Source::Local).to receive(:puts)

    class Vanagon
      module Utilities
        def puts(*args)
        end
      end
    end
  end
end
