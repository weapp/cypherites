require 'multi_json'
require 'rest_client'

module Support
  class Runner
    def cypher hsh
      raw_response = RestClient.post("http://localhost:7474/db/data/cypher", MultiJson.dump(hsh), :content_type => :json, :accept => :json){|response, _request, _result| response }
      MultiJson.load(raw_response)
    end

    def transaction hsh
      hsh = {statements:[{statement: hsh[:query], params: hsh[:params], resultDataContents: ["row","graph"],includeStats: true}]}
      raw_response = RestClient.post("http://localhost:7474/db/data/transaction/commit", MultiJson.dump(hsh), :content_type => :json, :accept => :json){|response, _request, _result| response }
      MultiJson.load(raw_response)
    end

    def call query, params={}, opts={}
      filter = opts[:filter] || "auto"
      mode = opts[:mode] || auto_mode(filter)

      send("#{filter}_#{mode}_filter", send(mode, query: query, params: params))
    end

    def auto_transaction_filter(result)
      auto_cypher_filter(result["results"].first)
    end

    def all_transaction_filter(result)
      all_cypher_filter(result["results"].first)
    end

    def stats_transaction_filter(result)
      all_cypher_filter(result["results"].first)["stats"]
    end

    def graph_transaction_filter(result)
      result["results"].first["data"].map{|res| res["graph"]}
    end

    def relationships_transaction_filter(result)
      graph_transaction_filter(result).map{|res| res["relationships"]}.flatten
    end

    def relationship_transaction_filter(result)
      relationships_transaction_filter(result).first
    end

    def auto_cypher_filter(result)
      if result["columns"]
        if result["columns"].count == 1
          result["data"].map{|row| parse_column(row.first)}
        else
          result["data"].map{|row| row.map{|c| parse_column(c)}}
        end
      else
        raise SyntaxError.new(result["message"])
      end
    end

    def all_cypher_filter(result)
      result
    end

    def one_cypher_filter(result)
      auto_cypher_filter(result).first
    end

    def parse_column(column)
      column.is_a?(Hash) && column.has_key?("data") ? column["data"] : column
    end

    def auto_mode(filter)
      [:stats, :graph, :relationship, :relationships].include?(filter) ? :transaction : :cypher
    end
  end
end

# POST http://localhost:7474/db/data/cypher
# Accept: application/json; charset=UTF-8
# Content-Type: application/json

