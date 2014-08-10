require 'spec_helper'

module Cypherites
  describe Statement do
    subject {Statement.new(:MATCH)}

    describe ".new" do
      it "clause is set" do
        expect(subject.clause).to be == :MATCH
      end
    end

    describe "#add" do
      it "predicate can be added" do
        subject.add("predicate")
        expect(subject.predicates).to eq ["predicate"]
      end

      it "multiple predicates can be added" do
        subject.add("predicate 0")
        subject.add("predicate 1")
        expect(subject.predicates).to eq ["predicate 0", "predicate 1"]
      end
    end

    describe "#join" do
      it "predicates must be separted by comma" do
        subject.add("predicate 1")
        subject.add("predicate 2")
        expect(subject.join).to eq "MATCH predicate 1, predicate 2"
      end

      it "predicates can't be merged if clause isn't joineable" do
        expect(subject).to receive(:joineable?){false}
        subject.add("predicate 1")
        subject.add("predicate 2")
        expect(subject.join).to eq "MATCH predicate 1\nMATCH predicate 2"
      end

      it "predicates must be separted by AND if caluse is where" do
        subject = Statement.new(:WHERE)
        subject.add("predicate 1")
        subject.add("predicate 2")
        expect(subject.join).to eq "WHERE predicate 1 AND predicate 2"
      end
    end

  end
end