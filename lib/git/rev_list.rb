require 'git'

module LibRevList
  def rev_list(committish = nil, opts = {})
    arr_opts = []

    opts.each do |k, v|
      # allow for passing, say, :max-count or :max_count
      k = k.to_s
      k.tr!('_', '-')
      if v && v.to_s.downcase == 'true'
        arr_opts << "--#{k}"
      elsif v
        arr_opts << "--#{k}=#{v}"
      end
    end

    arr_opts << committish if committish

    command('rev-list', arr_opts)
  end
end

module Git
  class Lib
    include LibRevList
  end
end

module Git
  class Base
    def rev_list(committish = nil, opts = {})
      lib.rev_list(committish, opts)
    end
  end
end
