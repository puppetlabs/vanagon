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
  def update_submodules(**options)
    self.lib.update_submodules(options)
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
