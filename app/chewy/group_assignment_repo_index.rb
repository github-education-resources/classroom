# frozen_string_literal: true

class GroupAssignmentRepoIndex < Chewy::Index
  define_type GroupAssignmentRepo.includes(:group_assignment, :group) do
    field :id
    field :github_repo_id
    field :created_at
    field :updated_at

    field :group_assignment_title, value: ->(group_assignment_repo) { group_assignment_repo&.group_assignment&.title }
    field :group_title,            value: ->(group_assignment_repo) { group_assignment_repo&.group&.title            }
  end
end
