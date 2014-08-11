require_relative "predicate"
require_relative "statement"
require_relative "query_out_boxing"

module Cypherites
  class Query

    include QueryOutBoxing
    
    attr_accessor :runner, :statement_builder, :predicate_builder, :sorted, :sep

    def initialize(runner=nil, statement_builder=Statement.method(:new), predicate_builder=Predicate.method(:build))
      self.sorted = true
      self.runner = runner
      self.statement_builder = statement_builder
      self.predicate_builder = predicate_builder
      @statements = []
      new_phase
      @sep = "\n"
      @auto_phases = true
    end

    def new_phase
      @last_clause = nil
      @statements << Hash.new{|h,k| h[k] = self.statement_builder.(k) }
      self
    end

    def no_sort
      self.sorted = false
      self
    end

    def create *args
      statement :CREATE, *args
    end

    def start *args
      statement :START, *args
    end

    def match *args
      new_phase if @auto_phases && @statements.last.keys != [:MATCH]
      statement :MATCH, *args
    end

    def optional_match *args
      statement :"OPTIONAL MATCH", *args
    end

    def where *args
      statement :WHERE, *args
    end

    def delete *args
      statement :DELETE, *args
    end

    def return *args
      statement :RETURN, *args
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

    def order_by *args
      statement :"ORDER BY", *args
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

    def skip *args
      statement :SKIP, *args
    end

    def unwind *args
      statement :UNWIND, *args
    end

    def using *args
      statement :USING, *args
    end

    def using_index predicate, *opts
      add_predicate :USING, predicate_builder.("INDEX #{predicate}", *opts)
      self
    end

    def using_scan predicate, *opts
      add_predicate :USING, predicate_builder.("SCAN #{predicate}", *opts)
      self
    end

    def merge *args
      statement :MERGE, *args
    end

    def union predicate="", *args
      new_phase
      statement :UNION, predicate, *args
      new_phase
    end

    def with *args
      new_phase if @auto_phases && @statements.last.keys != [:WITH]
      statement :WITH, *args
    end

    def limit *args
      statement :LIMIT, *args
    end

    def execute *args
      runner.call(self, *args)
    end

    def to_cypher(sep=@sep)
      all_sorted_statements.map(&:join).join(sep)
    end

    def to_str
      to_cypher
    end

    def to_s
      to_cypher
    end

    def inspect
      to_cypher
    end

    def == other
      to_s == other.to_s
    end

    private
    CLAUSES = [:WITH, :UNION, :UNWIND, :MERGE, :START, :MATCH, :USING, :"OPTIONAL MATCH", :WHERE, :CREATE, :FOREACH, :SET, :DELETE, :REMOVE, :RETURN, :"ORDER BY", :SKIP, :LIMIT]


    def statement clause, predicate, *opts
      statement! clause, predicate, *opts
      self
    end

    def statement! clause, predicate, *opts
      add_predicate clause, predicate_builder.(predicate, *opts)
    end

    def add_predicate clause, predicate
      @last_clause = clause
      @statements.last[clause].add predicate
    end

    def all_sorted_statements
      arr = []
      @statements.each do |statements|
       arr += sorted_statements(statements).map{|clause, statement| statement}
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
        statements.sort_by { |clause, statement| CLAUSES.index(clause) }
      else
        statements
      end
    end

    def return_node_or_rel func, *fields
      fields.each do |field| 
        self.return("id(#{field}) as #{field}_id, #{func}(#{field}) as #{field}_#{func}, #{field}")
      end
      self
    end
  end
end
