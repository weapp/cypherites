require 'spec_helper'

module Cypherites

  describe Query do

    let(:execute) { ->(query){["first", "last"]} }
    let(:q)       { Query.new(execute) }

    describe "#to_a" do
      it "must return array" do
        expect(q.to_a).to be_an Array
      end
    end
    
    describe "#all" do
      it "must return array" do
        expect(q.all).to be == ["first", "last"]
      end
    end

    describe "#call" do
      it "must return array" do
        expect(q.()).to be == ["first", "last"]
      end
    end

    describe "#first" do
      it "must return array" do
        expect(q.first).to be == "first"
      end
    end

    describe "#last" do
      it "must return array" do
        expect(q.last).to be == "last"
      end
    end

  end

end