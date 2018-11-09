require 'tsort'

class Vanagon
  # This class encapsulates a directed acyclic graph (DAG).
  class DAG
    include TSort

    def initialize(hash)
      @hash = hash
    end

    def tsort_each_node(&block)
      @hash.each_key(&block)
    end

    def tsort_each_child(node, &block)
      @hash.fetch(node).each(&block)
    end
  end
end
