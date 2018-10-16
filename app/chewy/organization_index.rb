# frozen_string_literal: true

class OrganizationIndex < Chewy::Index
  define_type Organization do
    field :id
    field :github_id
    field :slug
    field :title
    field :created_at
    field :updated_at

    field :login, value: ->(organization) { organization&.github_organization&.login }
    field :name,  value: ->(organization) { organization&.github_organization&.name  }
  end
end
