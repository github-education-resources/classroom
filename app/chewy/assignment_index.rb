# frozen_string_literal: true

class AssignmentIndex < Chewy::Index
  define_type Assignment.includes(:organization) do
    field :id
    field :slug
    field :title
    field :created_at
    field :updated_at

    field :organization_login, value: ->(assignment) { assignment&.organization&.github_organization&.login }
  end
end
