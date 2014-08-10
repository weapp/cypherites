require 'spec_helper'

module Cypherites
  describe Statement do

    describe ".new" do
      it "clause is set" do
        s = Statement.new(:MATCH)
        expect(s.clause).to be == :MATCH 
      end
    end

    describe "#add" do
      let(:statement) { Statement.new(:MATCH) }

      it "predicate can be added" do
        statement.add("predicate")
        expect(statement.predicates).to eq ["predicate"]
      end

      it "complex predicate can be added" do
        statement.add("predicate ?", 0)
        expect(statement.predicates).to eq ["predicate 0"]
      end

      it "multiple predicates can be added" do
        statement.add("predicate ?", 0)
        statement.add("predicate ?", 1)
        expect(statement.predicates).to eq ["predicate 0", "predicate 1"]
      end
    end

    describe "#join" do
      it "predicates must be separted by comma" do
        statement = Statement.new(:MATCH)
        statement.add("predicate 1")
        statement.add("predicate 2")
        expect(statement.join).to eq "MATCH predicate 1, predicate 2"
      end

      it "predicates must be separted by and if caluse is where" do
        statement = Statement.new(:WHERE)
        statement.add("predicate 1")
        statement.add("predicate 2")
        expect(statement.join).to eq "WHERE predicate 1 AND predicate 2"
      end
    end

  end
end