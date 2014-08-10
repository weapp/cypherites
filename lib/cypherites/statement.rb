module Cypherites
  class Statement
    attr_accessor :predicates, :clause

    def initialize(clause)
      @clause = clause
      @predicates = []
    end

    def add(predicate)
      predicates << predicate
    end

    def join
      if joineable?
        "#{clause} #{predicates.join(separator)}"
      else
        predicates.map{|p| "#{clause} #{p}"}
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