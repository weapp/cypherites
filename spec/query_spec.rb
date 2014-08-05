require 'spec_helper'

module Cypherites
  describe Query do
    let(:runner){double("runner")}

    describe ".new" do
      it "adapter is set" do
        q = Query.new(runner)
        expect(q.runner).to be runner
      end

      it("adapter is optional"){ is_expected.to be_truthy}
    end

    describe "#execute" do
      it "must call @runner" do
        q = Query.new(runner)
        expect(runner).to receive(:call).with(q, {foo: "bar", baz: "qux"})
        q.execute({foo: "bar", baz: "qux"})
      end
    end

    describe "#statement" do

      it "must return itself" do
        expect(subject.statement(:MATCH, "predicate")).to be subject
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
          expect(subject.send(clause, "predicate")).to be subject
        end

        it "must call #statement with correct symbol" do
          sym = clause.upcase.gsub(/_/, " ").to_sym
          
          st_build_mock = double("st_build_mock")
          expect(st_build_mock).to receive(:new).with(sym){Statement.new(sym)}        
          
          subject.statement_builder = st_build_mock
          subject.send(clause, "predicate")
        end
      end
    end

    describe "#return_node" do
      it "must return itself" do
        expect(subject.return_node("node1")).to be subject
      end

      it "must call #statement with correct symbol" do
          st_build_mock = double("st_build_mock")
          expect(st_build_mock).to receive(:new).with(:RETURN){Statement.new(:RETURN)}        
          
          subject.statement_builder = st_build_mock
          subject.return_node("node1")
      end
    end

    describe "#return_rel" do
      it "must return itself" do
        expect(subject.return_rel("rel")).to be subject
      end

      it "must call #statement with correct symbol" do
          st_build_mock = double("st_build_mock")
          expect(st_build_mock).to receive(:new).with(:RETURN){Statement.new(:RETURN)}        
          
          subject.statement_builder = st_build_mock
          subject.return_rel("rel")
      end
    end

    describe "#to_cypher" do
      it "returned sorted statements" do
        subject
          .limit("")
          .match("")
          .order_by("")
          .optional_match("")
          .return("")
          .start("")
          .where("")

        expect(subject.to_cypher).to be == "START  MATCH  OPTIONAL MATCH  WHERE  RETURN  ORDER BY  LIMIT "
      end

      it "example query must work" do
        subject
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

        expect(subject.to_cypher).to be == result.join(" ")
      end

      it "example first" do
        subject
          .match("(object)")
          .return_node("object")
          .order_by("id(object) ASC")
          .limit(1)

        result = 'MATCH (object) RETURN id(object) as object_id, labels(object) as object_labels, object ORDER BY id(object) ASC LIMIT 1'

        expect(subject.to_cypher).to be == result
      end

      it "example last" do
        subject
          .match("(object)")
          .return_node("object")
          .order_by("id(object) DESC")
          .limit(1)

        result = 'MATCH (object) RETURN id(object) as object_id, labels(object) as object_labels, object ORDER BY id(object) DESC LIMIT 1'

        expect(subject.to_cypher).to be == result
      end

      it "example find" do
        subject
          .start("object=node(?)", 99)
          .return_node("object")
          .order_by("id(object) DESC")
          .limit(1)

        result = 'START object=node(99) RETURN id(object) as object_id, labels(object) as object_labels, object ORDER BY id(object) DESC LIMIT 1'

        expect(subject.to_cypher).to be == result
      end

      it "example all" do
        subject
          .match("(object)")
          .return_node("object")

        result = 'MATCH (object) RETURN id(object) as object_id, labels(object) as object_labels, object'

        expect(subject.to_cypher).to be == result
      end

      it "example clear" do
        subject
          .match("(object)")
          .optional_match("(object)-[relation]-()")
          .delete(:object)
          .delete(:relation)

        result = 'MATCH (object) OPTIONAL MATCH (object)-[relation]-() DELETE object, relation'

        expect(subject.to_cypher).to be == result
      end
    end
  end
end