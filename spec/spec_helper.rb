RSpec.configure do |c|
  c.before do
    allow($stdout).to receive(:puts)
    allow($stderr).to receive(:puts)
  end
end
