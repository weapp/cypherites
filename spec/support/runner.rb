require 'multi_json'
require 'rest_client'

module Support
  class Runner
    def post hsh
      response = RestClient.post("http://localhost:7474/db/data/cypher", MultiJson.dump(hsh), :content_type => :json, :accept => :json)#{|response, request, result| response }
      MultiJson.load(response)
    end

    def call query, params={}
      post(query: query, params: params)
    end
  end
end

# POST http://localhost:7474/db/data/cypher
# Accept: application/json; charset=UTF-8
# Content-Type: application/json

