# frozen_string_literal: true

def graphql_query(query, variables: {}, as:)
  GitHubClassroomSchema.execute(query, variables: variables, context: { current_user: as }, operation_name: nil)
end
