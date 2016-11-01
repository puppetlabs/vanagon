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
