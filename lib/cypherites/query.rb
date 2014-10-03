require_relative "query_out_boxing"
require_relative "basic_query"

module Cypherites
  class Query < BasicQuery

    include QueryOutBoxing
    
    attr_accessor :runner, :sorted

    def initialize(runner=nil)
      super()
      self.sorted = true
      self.runner = runner
    end

    def no_sort
      self.sorted = false
      self
    end

    def distinct
      modify_last("DISTINCT %s")
    end

    def as(field)
      modify_last( "%s AS #{field}")
    end

    def desc
      modify_last( "%s DESC")
    end

    def asc
      modify_last( "%s ASC")
    end

    def return_node *fields
      return_node_or_rel "labels", *fields
    end

    def return_rel *fields
      return_node_or_rel "type", *fields
    end

    def order *args
      args.each do |option|
        if option.kind_of? Hash
          option.each do |field, asc_desc|
            order_by "#{field} #{asc_desc.to_s.upcase}"
          end
        else
          order_by option
        end
      end
      self
    end

    def unwind *args
      statement :UNWIND, *args
    end

    def using_index predicate, *opts
      add_predicate :USING, predicate_builder.("INDEX #{predicate}", *opts)
      self
    end

    def using_scan predicate, *opts
      add_predicate :USING, predicate_builder.("SCAN #{predicate}", *opts)
      self
    end

    def execute *args
      runner.call(self, *args)
    end

    def to_cypher(sep=@sep)
      all_sorted_statements.map(&:join).join(sep)
    end

    def == other
      to_s == other.to_s
    end

    private
    CLAUSES = [:UNION, :WITH, :UNWIND, :MERGE, :START, :MATCH, :USING, :"OPTIONAL MATCH", :WHERE, :CREATE, :FOREACH, :SET, :DELETE, :REMOVE, :RETURN, :"ORDER BY", :SKIP, :LIMIT]

    def all_sorted_statements
      arr = []
      @statements.each do |statements|
       arr += sorted_statements(statements).map{|_clause, statement| statement}
      end
      arr
    end

    def modify_last(pattern)
      if @last_clause
        last_statements = @statements.last[@last_clause]
        last_statements.modify_last(pattern)
      end
      self
    end

    def sorted_statements statements
      if sorted
        statements.sort_by { |clause, _statement| CLAUSES.index(clause) }
      else
        statements
      end
    end

    def return_node_or_rel func, *fields
      fields.each do |field| 
        self.return("id(#{field}) AS #{field}_id, #{func}(#{field}) AS #{field}_#{func}, #{field}")
      end
      self
    end
  end
end
