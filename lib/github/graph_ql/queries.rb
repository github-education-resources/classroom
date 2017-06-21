# frozen_string_literal: true

module GitHub
  module GraphQL
    module Queries
      # Since GraphQL queries take a long time to parse, it's recommended to assign them to
      # static constants and parse at boot time.

      # This file defines all the parsed queries we need in the app.

      ID_FOR_ASSIGNMENT_REPO = GitHub::GraphQL.parse <<-'GRAPHQL'
        query($owner: String!, $name: String!) {
          repository(owner: $owner, name: $name){
            id
          }
        }
      GRAPHQL
    end
  end
end
