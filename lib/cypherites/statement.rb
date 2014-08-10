require_relative "predicate"

module Cypherites
  class Statement
    attr_accessor :predicates, :clause

    def initialize(clause)
      @clause = clause
      @predicates = []
    end

    def add(predicate, *opts)
      predicates << Predicate.build(predicate, *opts)
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