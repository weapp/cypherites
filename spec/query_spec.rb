require 'spec_helper'

module Cypherites
  describe Query do

    describe ".new" do
      it "adapter is set" do
        runner = OpenStruct.new
        q = Query.new(runner)
        expect(q.runner).to eq runner
      end

      it "adapter is optional" do
        q = Query.new()
        expect(q).to be_truthy # passes if actual is truthy (not nil or false)
      end
    end

    describe "#execute" do
      it "must call @runner" do
        runner = double("runner")
        q = Query.new(runner)
        expect(runner).to receive(:call).with(q)        
        q.execute
      end
    end

    describe "#statement" do

      it "must return itself" do
        @q = Query.new
        expect(@q.statement(:MATCH, "predicate")).to be == @q
      end
      
      it "must store the statement" do
        q = Query.new
        q.statement(:MATCH, "predicate")
        statements = q.statements
        expect(statements.keys.first).to be == :MATCH
        expect(statements.values.first.predicates).to be == ["predicate"]
      end
    end

    common_clauses = %w{match optional_match where return order_by limit delete}

    common_clauses.each do |clause|
      describe "##{clause}" do
        it "must return itself" do
          q = Query.new
          expect(q.send(clause, "predicate")).to be == q
        end

        it "must call #statement with correct symbol" do
          sym = clause.upcase.gsub(/_/, " ").to_sym
          
          st_build_mock = double("st_build_mock")
          expect(st_build_mock).to receive(:new).with(sym){Statement.new(sym)}        
          
          q = Query.new
          q.statement_builder = st_build_mock
          q.send(clause, "predicate")
        end
      end
    end

    describe "#return_node" do
      it "must return itself" do
        q = Query.new
        expect(q.return_node("node1")).to be == q 
      end

      it "must call #statement with correct symbol" do
          st_build_mock = double("st_build_mock")
          expect(st_build_mock).to receive(:new).with(:RETURN){Statement.new(:RETURN)}        
          
          q = Query.new
          q.statement_builder = st_build_mock
          q.return_node("node1")
      end
    end

    describe "#return_rel" do
      it "must return itself" do
        q = Query.new
        expect(q.return_rel("rel")).to be == q
      end

      it "must call #statement with correct symbol" do
          st_build_mock = double("st_build_mock")
          expect(st_build_mock).to receive(:new).with(:RETURN){Statement.new(:RETURN)}        
          
          q = Query.new
          q.statement_builder = st_build_mock
          q.return_rel("rel")
      end
    end

    describe "#to_cypher" do
      it "returned sorted statements" do
        q = Query.new
          .limit("")
          .match("")
          .order_by("")
          .optional_match("")
          .return("")
          .start("")
          .where("")

        expect(q.to_cypher).to be == "START  MATCH  OPTIONAL MATCH  WHERE  RETURN  ORDER BY  LIMIT "
      end

      it "example query must work" do
        q = Query.new
          .limit(10)
          .match("(object ?)", {key: "value"})
          .order_by(:id)
          .optional_match("(object)->[r]->()")
          .return("id(object) as id")
          .return("object")
          .return("r")
          .start("object = node(?)", 1)
          .where(or: [["object.field = ?", "value"], ["wadus = ?", "fadus"]])
          .where("object.field = ?", "value")
          .where("object.field2 = ?", "value2")

        result = [
          "START object = node(1)",
          "MATCH (object {key : 'value'})",
          "OPTIONAL MATCH (object)->[r]->()",
          "WHERE ((object.field = 'value') OR (wadus = 'fadus'))",
                 "and object.field = 'value' and object.field2 = 'value2'",
          "RETURN id(object) as id, object, r",
          "ORDER BY id",
          "LIMIT 10"
        ]

        expect(q.to_cypher).to be == result.join(" ")
      end

      it "example first" do
        q = Query.new
          .match("(object)")
          .return_node("object")
          .order_by("id(object) ASC")
          .limit(1)

        result = 'MATCH (object) RETURN id(object) as object_id, labels(object) as object_labels, object ORDER BY id(object) ASC LIMIT 1'

        expect(q.to_cypher).to be == result
      end

      it "example last" do
        q = Query.new
          .match("(object)")
          .return_node("object")
          .order_by("id(object) DESC")
          .limit(1)

        result = 'MATCH (object) RETURN id(object) as object_id, labels(object) as object_labels, object ORDER BY id(object) DESC LIMIT 1'

        expect(q.to_cypher).to be == result
      end

      it "example find" do
        q = Query.new
          .start("object=node(?)", 99)
          .return_node("object")
          .order_by("id(object) DESC")
          .limit(1)

        result = 'START object=node(99) RETURN id(object) as object_id, labels(object) as object_labels, object ORDER BY id(object) DESC LIMIT 1'

        expect(q.to_cypher).to be == result
      end

      it "example all" do
        q = Query.new
          .match("(object)")
          .return_node("object")

        result = 'MATCH (object) RETURN id(object) as object_id, labels(object) as object_labels, object'

        expect(q.to_cypher).to be == result
      end

      it "example clear" do
        q = Query.new
          .match("(object)")
          .optional_match("(object)-[relation]-()")
          .delete(:object)
          .delete(:relation)

        result = 'MATCH (object) OPTIONAL MATCH (object)-[relation]-() DELETE object, relation'

        expect(q.to_cypher).to be == result
      end
    end
  end
end