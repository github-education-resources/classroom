require_relative "assignment_repo"

class Types
  class Assignment < GraphQL::Schema::Object
    require_relative "classroom"

    # To see an assignment, you must be an admin on the assignment organization
    def self.authorized?(assignment, context)
      super && context[:current_user] && assignment.organization.users.include?(context[:current_user])
    end

    implements GraphQL::Relay::Node.interface

    global_id_field :id

    field :title, String, description: "The Assignment title.", null: false

    field :slug, String, description: "The Assignment slug.", null: false

    field :public, Boolean, description: "Weather or not this assignment uses public repos.", null: false

    def public
      object.public?
    end

    field :classroom, Types::Classroom, description: "The assignment Classroom", null: false

    def classroom
      object.organization
    end

    field :submissions, Types::AssignmentRepo.connection_type, description: "Student submission repos for the assignment", null: true, connection: true

    def submissions
      object.repos
    end

    field :deadline_at, String, description: "The assignment deadline", null: true

    def deadline_at
      if object.deadline
        object.deadline.deadline_at.to_s
      end
    end

    field :deadline_passed, Boolean, description: "Whether or not the assignment deadline has passed", null: false

    def deadline_passed
      return false unless object.deadline

      object.deadline.passed?
    end
  end
end
