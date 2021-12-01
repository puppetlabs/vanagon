require 'git'

module BasicSubmodulePrimitives
  # Extend Git::Lib to support shotgunning submodules. This command
  # is not smart, and it has very poor support for submodule options.
  # For example, you can't pass any arguments to the handful of submodule
  # options that accept them (like --depth). We may extend it later,
  # but for rev. 0001, simply initializing them will suffice
  def update_submodules(**options)
    arr_opts = ['update']
    options.each_pair do |k, v|
      arr_opts << "--#{k}" if v
    end
    Dir.chdir(@git_work_dir) do
      command('submodule', arr_opts)
    end
  end
end

module BasicSubmodules
  # @example Initialize all git submodules
  #   >> repo = Git.clone("git@github.com:puppetlabs/facter.git", "facter", path: Dir.mktmpdir)
  #   => <Git::Base>
  #   >> repo.checkout "3.1.3
  #   => <String>
  #   >> repo.update_submodules(init: true)
  #   => <String>
  # @param [Hash] options any options to pass to `git submodule update`
  # @option options [Boolean] :init whether to initialize submodules when updating them
  # @option options [Boolean] :use the submodule's remote-tracking branch instead of superproject's SHA1 sum
  # @option options [Boolean] :no-fetch don't fetch new objects from the remote site.
  # @option options [Boolean] :force remove submodule's working tree even if modified
  # @option options [Boolean] :checkout checkout submodules in detached HEAD state
  # @option options [Boolean] :merge merge recorded commit for submodule into the current branch of the submodule
  # @option options [Boolean] :rebase rebase current branch of submodule onto the commit recorded in the superproject
  # @option options [Boolean] :recursive recurse into nested submodules
  # @return options [String] any output produced by `git` when submodules are initialized
  def update_submodules(**options)
    self.lib.update_submodules(**options)
  end
end

module Git
  class Lib
    include BasicSubmodulePrimitives
  end
end

module Git
  class Base
    include BasicSubmodules
  end
end
