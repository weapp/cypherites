require 'spec_helper'

module Cypherites
  describe Query do
    describe "#execute" do
      before{clear_query.execute}
      after{clear_query.execute}
      let (:clear_query){
        Query.new(runner)
            .match("(n:Test)")
            .optional_match("(n)-[r]-()")
            .delete("n").delete("r")
      }
      let(:runner){Support::Runner.new}
      subject {Query.new(runner)}

      context "General Clauses" do
        context "Return" do
          before do
            Query.new(runner).create("(a:Test { name:'A', happy: 'yeah'})-[:KNOWS]->(b:Test { name: 'B' })").execute
          end

          it {
            q = Query.new(runner).match("(n:Test { name: 'B' })").return("n")
            expect(q.call).to eq [{"name"=>"B"}]

          # it
            q = Query.new(runner).match("(n:Test { name: 'A' })-[r:KNOWS]->(c)").return("r")
            expect(q.call({}, filter: :relationship)["type"]).to eq "KNOWS"

          # it
            q = Query.new(runner).match("(n:Test { name: 'A' })").return("n.name")
            expect(q.call).to eq ["A"]

          # it
            q = Query.new(runner).match("p=(a:Test { name: 'A' })-[r]->(b)").return("*")
            expect(q.call({}, filter: :all)["columns"]).to eq ["a", "b", "p", "r"]

          # it
            q = Query.new(runner)
              .match("(`This isn't a common identifier`:Test)")
              .where("`This isn't a common identifier`.name='A'")
              .return("`This isn't a common identifier`.happy")
            expect(q.call).to eq ["yeah"]

          # it
            q = Query.new(runner)
              .match("(a:Test { name: 'A' })")
              .return("a.age AS SomethingTotallyDifferent, a.age > 30, \"I'm a literal\", (a)-->()")
            expect(q.call({}, filter: :all)["columns"]).to eq ["SomethingTotallyDifferent", "a.age > 30", "\"I'm a literal\"", "(a)-->()"]

          # it
            q = Query.new(runner)
              .match("(a:Test { name: 'A' })-->(b)")
              .return("b")
              .distinct
            expect(q.call).to eq [{"name"=>"B"}]
          }
        end
      end

      it {
        subject.create("(n:Test)").return("n")
        expect(subject.call).to eq([{}])
      }

      it {
        subject.create("(n:Person:Test)").return("n")
        expect(subject.call).to eq([{}])
      }

      it {
        subject.create("(n:Person:Swedish:Test)").return("n")
        expect(subject.call).to eq([{}])
      }

      it {
        subject.create("(n:Person:Test { name : 'Andres', title : 'Developer' })").return("n")
        expect(subject.call).to eq([{"title"=>"Developer", "name"=>"Andres"}])
      }

      it {
        subject.create("(a:Test { name : 'Andres' })").return("a")
        expect(subject.call).to eq([{"name"=>"Andres"}])
      }

      it {
        clear_query = Query.new(runner)
            .match("(n:Test)")
            .optional_match("(n)-[r]-()")
            .delete("n").delete("r")

        expect(clear_query.call({}, filter: :stats, mode: :transaction)).to be_truthy

        q = Query.new(runner)
            .create("(a:Test { name : 'Node A' })")
            .return("a")
        expect(q.call).to eq([{"name"=>"Node A"}])

        q = Query.new(runner)
            .create("(b:Test { name : 'Node B' })")
            .return("b")
        expect(q.call).to eq([{"name"=>"Node B"}])

        subject
          .match("(a:Test)")
          .match("(b:Test)")
          .where("a.name = 'Node A'")
          .where("b.name = 'Node B'")
          .create("(a)-[r:RELTYPE]->(b)")
          .return("r")

        expect(subject.call({}, filter: :relationship)["type"]).to eq "RELTYPE"

        clear_stats = clear_query.call({}, filter: :stats)
        expect(clear_stats["nodes_deleted"]).to be 2
        expect(clear_stats["relationship_deleted"]).to be 1

      }

      it {
        subject
          .create("p =(andres:Test { name:'Andres' })-[:WORKS_AT]->(neo:Test)<-[:WORKS_AT]-(michael:Test { name:'Michael' })")
          .return("p")

        path = subject.call({}, filter: :one)

        expect(path["nodes"].count).to be 3
        expect(path["relationships"].count).to be 2
        expect(path["length"]).to be 2
      }

      it {
        subject
          .create("(n:Person:Test { props })")
          .return("n")

        params = {
          props: {
            "name" => "Andres",
            "position" => "Developer"
          }
        }

        result = subject.execute(params, filter: :one)

        expect(result).to eq params[:props]
      }

    end
  end
end