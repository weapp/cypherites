require_relative "predicate"
require_relative "statement"

module Cypherites
  class BasicQuery
    attr_accessor :statement_builder, :predicate_builder, :sep
    attr_reader :last_clause

    def initialize(statement_builder=Statement.method(:new), predicate_builder=Predicate.method(:build))
      self.statement_builder = statement_builder
      self.predicate_builder = predicate_builder
      @statements = []
      @sep = "\n"
      new_phase
    end

    def new_phase
      @last_clause = nil
      @statements << Hash.new{|h,k| h[k] = self.statement_builder.(k) }
      self
    end

    def create *args
      statement :CREATE, *args
    end

    def start *args
      statement :START, *args
    end

    def match *args
      new_phase if last_clauses != [:MATCH]
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
    end

    def with *args
      new_phase if last_clauses != [:WITH]
      statement :WITH, *args
    end

    def limit *args
      statement :LIMIT, *args
    end

    def to_cypher(sep=@sep)
      statements_to_cypher.map(&:join).join(sep)
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

    def last_clauses
      @statements.last.keys
    end

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

    def statements_to_cypher
      arr = []
      @statements.each do |statements|
       arr += statements.map{|clause, statement| statement}
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
  end
end
