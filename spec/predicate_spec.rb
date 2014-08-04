require 'spec_helper'

module Cypherites
  describe Predicate do

    describe ".new" do
      it "simple predicate is set" do
        p = Predicate.new("predicate")
        expect(p.predicate).to be == "predicate"
      end
    end

    describe ".build" do
      it "must create and generate a predicate" do
        expect(Predicate.build("predicate <?>", "args")).to be == "predicate <'args'>"
      end
    end

    describe "#generate" do
      it "string simple predicate is generated" do
        p = Predicate.new("predicate")
        expect(p.generate).to be == "predicate"
      end

      it "number predicate is generated" do
        p = Predicate.new(0)
        expect(p.generate).to be == "0"
      end

      it "symbol predicate is generated" do
        p = Predicate.new(:sym)
        expect(p.generate).to be == "sym"
      end

      it "hash predicate is generated" do
        p = Predicate.new(or: [["p1 ?", "args"], ["p2 <?> <?>", "arg1", "arg2"]])
        expect(p.generate).to be == "((p1 'args') OR (p2 <'arg1'> <'arg2'>))"
      end

      it "hash predicate is generated" do
        p = Predicate.new(or: ["p1", "p2"])
        expect(p.generate).to be == "((p1) OR (p2))"
      end

      it "string predicate with number is generated" do
        p = Predicate.new("predicate ?")
        expect(p.generate(0)).to be == "predicate 0"
      end

      it "string predicate with string is generated" do
        p = Predicate.new("predicate ?")
        expect(p.generate("string")).to be == "predicate 'string'"
      end

      it "string predicate with hash is generated" do
        p = Predicate.new("predicate ?")
        expect(p.generate({key: "value"})).to be == "predicate {key : 'value'}"
      end
    end

  end
end