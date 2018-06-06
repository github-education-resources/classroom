require "graphql"

require_relative "types/assignment_repo"
require_relative "types/user"
require_relative "types/classroom"
require_relative "types/assignment"

require_relative "types/mutation_type"
require_relative "types/query_type"

class GitHubClassroomSchema < GraphQL::Schema
  mutation(Types::MutationType)
  query(Types::QueryType)

  use GraphQL::Batch

  def self.object_from_id(id, context)
    decoded_string = Base64.strict_decode64(id)
    gid_type, class_name, database_id = decoded_string.scan(/([0-9])([a-zA-Z]+):([0-9]+)/).first

    # TODO: raise error here
    return unless gid_type == "0"

    class_name.constantize.find(database_id)
  end

  def self.resolve_type(abstract_type, object, context)
    # TODO: Support more than just Node abstract_types
    resolve_node(object, context)
  end

  def self.resolve_node(object, context)
    case object.class.name
    when "Organization"
      types["Classroom"]
    else
      types[object.class.name]
    end
  end
end
