require 'git'

module UnshallowRepositories
  # Extend Git::Lib#fetch to support unshallowing an existing
  # shallow repo.
  def fetch(remote, opts)
    arr_opts = [remote]
    arr_opts << '--tags' if opts[:t] || opts[:tags]
    arr_opts << '--prune' if opts[:p] || opts[:prune]
    arr_opts << '--unshallow' if opts[:unshallow]

    command('fetch', arr_opts)
  end
end

module Git
  class Lib
    include UnshallowRepositories
  end
end
