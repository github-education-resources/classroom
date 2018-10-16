# frozen_string_literal: true

class GroupAssignmentIndex < Chewy::Index
  define_type GroupAssignment.includes(:organization) do
    field :id
    field :slug
    field :title
    field :created_at
    field :updated_at

    field :organization_login,
      value: ->(group_assignment) { group_assignment&.organization&.github_organization&.login }
  end
end
