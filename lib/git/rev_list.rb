require 'git'

module LibRevList
  def rev_list(committish = nil, opts = {}) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
    arr_opts = []

    if opts[:"max-count"] || opts[:max_count]
      arr_opts << "--max-count=#{opts[:'max-count'] || opts[:max_count]}"
    end

    if opts[:"max-age"] || opts[:max_age]
      arr_opts << "--max-age=#{opts[:'max-age'] || opts[:max_age]}"
    end

    if opts[:"min-age"] || opts[:min_age]
      arr_opts << "--min-age=#{opts[:'min-age'] || opts[:min_age]}"
    end

    arr_opts << '--sparse' if opts[:sparse]
    arr_opts << '--no-merges' if opts[:"no-merges"] || opts[:no_merges]

    if opts[:"min-parents"] || opts[:min_parents]
      arr_opts << "--min-parents=#{opts[:'min-parents'] || opts[:min_parents]}"
    end

    arr_opts << '--no-min-parents' if opts[:'no-min-parents'] || opts[:no_min_parents]

    if opts[:"max-parents"] || opts[:max_parents]
      arr_opts << "--max-parents=#{opts[:'max-parents'] || opts[:max_parents]}"
    end

    arr_opts << '--no-max-parents' if opts[:'no-max-parents'] || opts[:no_max_parents]

    arr_opts << '--remove-empty' if opts[:'remove-empty'] || opts[:remove_empty]
    arr_opts << '--all' if opts[:all]
    arr_opts << '--branches' if opts[:branches]
    arr_opts << '--tags' if opts[:tags]
    arr_opts << '--remotes' if opts[:remotes]
    arr_opts << '--stdin' if opts[:stdin]
    arr_opts << '--quiet' if opts[:quiet]

    arr_opts << '--topo-order' if opts[:"topo-order"] || opts[:topo_order]
    arr_opts << '--date-order' if opts[:"date-order"] || opts[:date_order]
    arr_opts << '--reverse' if opts[:reverse]

    arr_opts << '--parents' if opts[:parents]
    arr_opts << '--children' if opts[:children]
    arr_opts << '--objects | --objects-edge' if opts[:objects] || opts[:"objects-edge"]
    arr_opts << '--unpacked' if opts[:unpacked]
    arr_opts << '--header | --pretty' if opts[:header] || opts[:pretty]
    arr_opts << "--abbrev=#{opts[:abbrev]}" if opts[:abbrev]
    arr_opts << "--abbrev=#{opts[:"no-abbrev"]}" if opts[:"no-abbrev"] || opts[:no_abbrev]
    arr_opts << '--abbrev-commit' if opts[:"abbrev-commit"] || opts[:abbrev_commit]
    arr_opts << '--left-right' if opts[:"left-right"] || opts[:left_right]
    arr_opts << '--count' if opts[:count]

    arr_opts << '--bisect' if opts[:bisect]
    arr_opts << '--bisect-vars' if opts[:"bisect-vars"] || opts[:bisect_vars]
    arr_opts << '--bisect-all' if opts[:"bisect-all"] || opts[:bisect_all]

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