# frozen_string_literal: true

require 'graphql/client/http'

module GitHub
  module GraphQL
    class QueryError < StandardError; end
    class ParseError < StandardError; end

    ENDPOINT_URL = 'https://api.github.com/graphql'
    SCHEMA_URI   = 'db/graphql_schema.json'

    def self.schema
      @graphql_schema ||= ::GraphQL::Client.load_schema(SCHEMA_URI)
    end

    # All query definitions must be parsed to a static constant before being excecuted
    # This method takes a string query and parses it into a Definition
    def self.parse(string_query)
      Client.unauthenticated_client.parse(string_query)
    rescue ::GraphQL::ParseError
      raise ParseError, 'Could not parse the query'
    end
  end
end
