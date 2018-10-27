# frozen_string_literal: true

class AssignmentRepoIndex < Chewy::Index
  define_type AssignmentRepo.includes(:assignment, :repo_access, :user) do
    field :id
    field :github_repo_id
    field :created_at
    field :updated_at

    field :assignment_title, value: ->(assignment_repo) { assignment_repo&.assignment&.title        }
    field :user_login,       value: ->(assignment_repo) { assignment_repo&.user&.github_user&.login }
  end
end
