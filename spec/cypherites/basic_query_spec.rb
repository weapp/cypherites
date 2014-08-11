require 'spec_helper'

module Cypherites
  describe BasicQuery do
    let(:runner){double("runner")}

    describe ".new" do
      it("adapter is optional"){ is_expected.to be_truthy}
    end

    common_clauses = %w{using unwind merge union skip create match optional_match where return order_by limit delete with}

    common_clauses.each do |clause|
      describe "##{clause}" do
        it "must return itself" do
          expect(subject.send(clause, "predicate")).to be subject
        end

        it "must call #statement with correct symbol" do
          sym = clause.upcase.gsub(/_/, " ").to_sym

          st_build_mock = double("st_build_mock")
          expect(st_build_mock).to receive(:call).with(sym){Statement.new(sym)}

          subject.statement_builder = st_build_mock
          subject.send(clause, "predicate")
        end
      end
    end


    describe "#to_cypher" do
      it "returned statements" do
        subject
          .match("")
          .create("")
          .skip("")
          .limit("")
          .order_by("")
          .optional_match("")
          .return("")
          .start("")
          .where("")

        result = "MATCH CREATE SKIP LIMIT ORDER BY OPTIONAL MATCH RETURN START WHERE "

        expect(subject.to_cypher("")).to be == result
      end

      it "break sorted with new_phase" do
        subject
          .return("")
          .new_phase
          .start("")

        expect(subject.to_cypher).to be == "RETURN \nSTART "
      end

      it "with clause break sorted" do
        subject
          .return("")
          .with("")
          .start("")

        expect(subject.to_cypher).to be == "RETURN \nWITH \nSTART "
      end

    end


    context "Some examples of queries" do
      it "example query must work" do
        subject
          .start("object = node(?)", 1)
          .match("(object ?)", {key: "value"})
          .optional_match("(object)->[r]->()")
          .where(or: [["object.field = ?", "value"], ["wadus = ?", "fadus"]])
          .where("object.field = ?", "value")
          .where("object.field2 = ?", "value2")
          .return("id(object)", as: "id")
          .return("object")
          .return("r")
          .order_by(:id)
          .skip(3)
          .limit(10)

        result = "START object = node(1)\n" +
                 "MATCH (object {key : 'value'})\n" +
                 "OPTIONAL MATCH (object)->[r]->()\n" +
                 "WHERE ((object.field = 'value') OR (wadus = 'fadus')) "+
                 "AND object.field = 'value' AND object.field2 = 'value2'\n" +
                 "RETURN id(object) AS id, object, r\n" +
                 "ORDER BY id\n" +
                 "SKIP 3\n" +
                 "LIMIT 10"


        is_expected.to eq result
      end

      it "example first" do
        subject
          .match("(object)")
          .return("id(object) AS object_id, labels(object) AS object_labels, object")
          .order_by("id(object) ASC")
          .limit(1)

        result = "MATCH (object)\n" +
                 "RETURN id(object) AS object_id, labels(object) AS object_labels, object\n" +
                 "ORDER BY id(object) ASC\n" +
                 "LIMIT 1"

        is_expected.to eq result
      end

      it "example last" do
        subject
          .match("(object)")
          .return("id(object) AS object_id, labels(object) AS object_labels, object")
          .order_by("id(object) DESC")
          .limit(1)

        result = "MATCH (object)\n" +
                 "RETURN id(object) AS object_id, labels(object) AS object_labels, object\n" +
                 "ORDER BY id(object) DESC\n" +
                 "LIMIT 1"

        is_expected.to eq result
      end

      it "example find" do
        subject
          .start("object=node(?)", 99)
          .return("id(object) AS object_id, labels(object) AS object_labels, object")
          .order_by("id(object)")
          .limit(1)

        result = "START object=node(99)\n" + 
                 "RETURN id(object) AS object_id, labels(object) AS object_labels, object\n" + 
                 "ORDER BY id(object)\n" +
                 "LIMIT 1"

        is_expected.to eq result
      end

      it "example all" do
        subject
          .match("(object)")
          .return("id(object) AS object_id, labels(object) AS object_labels, object")

        result = "MATCH (object)\n" + 
                 "RETURN id(object) AS object_id, labels(object) AS object_labels, object"

        is_expected.to eq result
      end

      it "example clear" do
        subject
          .match("(object)")
          .optional_match("(object)-[relation]-()")
          .delete(:object)
          .delete(:relation)

        result = "MATCH (object)\n" +
                 "OPTIONAL MATCH (object)-[relation]-()\n" +
                 "DELETE object, relation"

        is_expected.to eq result
      end

      it "example match 2 nodes" do
        subject
          .match("(a:Person)")
          .match("(b:Person)")
          .where("a.name = 'Node A'")
          .where("b.name = 'Node B'")
          .create("(a)-[r:RELTYPE]->(b)")
          .return("DISTINCT r")

        result = "MATCH (a:Person), (b:Person)\n" +
                 "WHERE a.name = 'Node A' AND b.name = 'Node B'\n" +
                 "CREATE (a)-[r:RELTYPE]->(b)\n" +
                 "RETURN DISTINCT r"

        is_expected.to eq result
      end

      it "example match 2 nodes" do
        subject
          .unwind("{ events } AS event")
          .merge("(y:Year { year:event.year })")
          .merge("(y)<-[:IN]-(e:Event { id:event.id })")
          .return("e.id AS x")
          .order_by("x ASC, e.id")

        result = "UNWIND { events } AS event\n" + 
                 "MERGE (y:Year { year:event.year })\n" + 
                 "MERGE (y)<-[:IN]-(e:Event { id:event.id })\n" + 
                 "RETURN e.id AS x\n" + 
                 "ORDER BY x ASC, e.id"

        is_expected.to eq result
      end

      it "example auto-phases" do
        subject
          .match("(n { name: \"Anders\" })--(m)")
          .with("m")
          .order_by("m.name DESC")
          .limit(1)
          .match("(m)--(o)")
          .return("o.name")

        result = "MATCH (n { name: \"Anders\" })--(m)\n" + 
                 "WITH m\n" + 
                 "ORDER BY m.name DESC\n" + 
                 "LIMIT 1\n" + 
                 "MATCH (m)--(o)\n" + 
                 "RETURN o.name"

        is_expected.to eq result
      end

      it "example union" do
        subject
          .match("(n:Actor)")
          .return("n.name", as: "name")
          .union
          .match("(n:Movie)")
          .return("n.title AS name")

        result = "MATCH (n:Actor)\n" + 
                 "RETURN n.name AS name\n" + 
                 "UNION \n" +
                 "MATCH (n:Movie)\n" + 
                 "RETURN n.title AS name"

        is_expected.to eq result
      end

      it "example using index" do
        subject
          .match("(m:German)-->(n:Swedish)")
          .using("INDEX m:German(surname)")
          .using("INDEX n:Swedish(surname)")
          .where("m.surname = 'Plantikow'")
          .where("n.surname = 'Taylor'")
          .return("m")

        result = "MATCH (m:German)-->(n:Swedish)\n" +
                 "USING INDEX m:German(surname)\n" +
                 "USING INDEX n:Swedish(surname)\n" +
                 "WHERE m.surname = 'Plantikow' AND n.surname = 'Taylor'\n" +
                 "RETURN m"

        is_expected.to eq result
      end

      it "example using scan" do
        subject
          .match("(m:German)")
          .using("SCAN m:German")
          .where("m.surname = 'Plantikow'")
          .return("m")

        result = "MATCH (m:German)\n" +
                 "USING SCAN m:German\n" +
                 "WHERE m.surname = 'Plantikow'\n" +
                 "RETURN m"

        is_expected.to eq result
      end

      it "example using with" do
        subject
          .match("(n {name: 'John'})-[:FRIEND]-friend")
          .with("n")
          .with("count(friend) AS friendsCount")
          .where("friendsCount > 3")
          .return("n")
          .return("friendsCount")

        result = "MATCH (n {name: 'John'})-[:FRIEND]-friend\n" +
                 "WITH n, count(friend) AS friendsCount\n" +
                 "WHERE friendsCount > 3\n" +
                 "RETURN n, friendsCount"

        is_expected.to eq result
      end

    end


  end
end