# frozen_string_literal: true

class UserIndex < Chewy::Index
  define_type User do
    field :id
    field :uid
    field :created_at
    field :updated_at
    field :last_active_at

    field :login, value: ->(user) { user.github_user.login }
    field :name,  value: ->(user) { user.github_user.name  }
  end
end
