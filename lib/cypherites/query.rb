require_relative "statement"
require_relative "query_out_boxing"

module Cypherites
  class Query

    include QueryOutBoxing
    
    attr_accessor :runner, :statements, :statement_builder, :sorted

    def initialize(runner=nil, statement_builder=Statement)
      self.sorted = true
      self.runner = runner
      self.statement_builder = statement_builder
      self.statements = []
      new_phase
      @sep = "\n"
      @auto_phases = true
    end

    def new_phase
      statements << Hash.new{|h,k| h[k] = self.statement_builder.new(k) }
      self
    end

    def no_sort
      self.sorted = false
      self
    end

    def statement clause, predicate, *opts
      statement! clause, predicate, *opts
      self
    end

    def statement! clause, predicate, *opts
      self.statements.last[clause].add(predicate, *opts)
    end

    def create *args
      statement :CREATE, *args
    end

    def start *args
      statement :START, *args
    end

    def match *args
      new_phase  if @auto_phases && statements.last.keys != [:MATCH]
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

    def return_node *fields
      fields.each do |field| 
        self.return("id(#{field}) as #{field}_id, labels(#{field}) as #{field}_labels, #{field}")
      end
      self
    end

    def return_rel *fields
      fields.each do |field| 
        self.return("id(#{field}) as #{field}_id, type(#{field}) as #{field}_type, #{field}")
      end
      self
    end

    def order_by *args
      statement :"ORDER BY", *args
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

    def merge *args
      statement :MERGE, *args
    end

    def union predicate="", *args
      new_phase
      statement :UNION, predicate, *args
      new_phase
    end

    def with *args
      new_phase if @auto_phases
      statement :WITH, *args
    end

    def limit *args
      statement :LIMIT, *args
    end

    def execute *args
      runner.call(self, *args)
    end

    def to_cypher
      all_sorted_statements.map(&:join).join(@sep)
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
    CLAUSES = [:UNION, :UNWIND, :MERGE, :START, :MATCH, :USING, :"OPTIONAL MATCH", :WHERE, :CREATE, :WITH, :FOREACH, :SET, :DELETE, :REMOVE, :RETURN, :"ORDER BY", :SKIP, :LIMIT]

    def all_sorted_statements
      arr = []
      self.statements.each do |statements|
       arr += sorted_statements(statements).map{|clause, statement| statement}
      end
      arr
    end

    def sorted_statements statements
      if sorted
        statements.sort_by { |clause, statement| CLAUSES.index(clause) }
      else
        statements
      end
    end
  end
end
