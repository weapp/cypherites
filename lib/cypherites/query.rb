require_relative "statement"
require_relative "query_out_boxing"

class Query

  include QueryOutBoxing
  
  attr_accessor :runner, :statements, :statement_builder

  def initialize(runner=nil, statement_builder=Statement)
    self.runner = runner
    self.statement_builder = statement_builder
    self.statements = Hash.new{|h,k| h[k] = self.statement_builder.new(k) }
  end

  def statement clause, predicate, *opts
    statement! clause, predicate, *opts
    self
  end

  def statement! clause, predicate, *opts
    self.statements[clause].add(predicate, *opts)
  end

  def start *args
    statement :START, *args
  end

  def match *args
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

  def limit *args
    statement :LIMIT, *args
  end

  def execute
    runner.call(self)
  end

  def to_cypher
    s = sorted_statements.values.map(&:join).join(" ")
  end

  private
  CLAUSES = [:START, :MATCH, :"OPTIONAL MATCH", :CREATE, :WHERE, :WITH, :FOREACH, :SET, :DELETE, :REMOVE, :RETURN, :"ORDER BY", :SKIP, :LIMIT]

  def sorted_statements
    self.statements.sort_by { |clause, params| CLAUSES.index(clause) }.to_h
  end
end
