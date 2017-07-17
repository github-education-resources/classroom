# frozen_string_literal: true

module GitHub
  module GraphQL
    class Client
      attr_accessor :token

      def initialize(token)
        @token = token
      end

      def query(definition, variables = {})
        response = authenticated_client.query(definition, variables: variables, context: { access_token: token })

        raise QueryError, response.errors[:data].join(', ') if response.errors.any?

        response.data
      end

      # Used for operations where a token isn't present and/or we don't need authentication
      # Right now, we use this for parsing queries, since this is done without the context of a user
      def self.unauthenticated_client
        @unauthenticated_client ||= ::GraphQL::Client.new(
          schema: GitHub::GraphQL.schema,
          execute: ::GraphQL::Client::HTTP.new(ENDPOINT_URL)
        )
      end

      private

      def authenticated_client
        @authenticated_client ||= ::GraphQL::Client.new(
          schema: GitHub::GraphQL.schema,
          execute: http_adapter
        )
      end

      # rubocop:disable NestedMethodDefinition
      def http_adapter
        @http_adapter ||= ::GraphQL::Client::HTTP.new(ENDPOINT_URL) do
          def headers(context)
            { 'Authorization' => "Bearer #{context[:access_token][:token]}" }
          end
        end
      end
      # rubocop:enable NestedMethodDefinition
    end
  end
end
