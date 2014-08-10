require_relative "predicate"

module Cypherites
  class Statement
    attr_accessor :predicates, :clause

    def initialize(clause, predicate_builder=Predicate)
      @clause = clause
      @predicates = []
      @predicate_builder = predicate_builder
    end

    def add(predicate, *opts)
      predicates << @predicate_builder.build(predicate, *opts)
    end

    def join
      if joineable?
        "#{clause} #{predicates.join(separator)}"
      else
        predicates.map{|p| "#{clause} #{p}"}.join("\n")
      end
    end

    def inspect
      predicates.inspect
    end

    private
    def separator
      clause == :WHERE ? " AND " : ", "
    end

    def joineable?
      ![:MERGE, :USING].include? clause
    end

  end
end