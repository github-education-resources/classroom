# frozen_string_literal: true

class StafftoolsIndex < Chewy::Index
  define_type Assignment.includes(:organization) do
    field :id
    field :slug
    field :title
    field :created_at
    field :updated_at

    field :organization_login, value: ->(assignment) { assignment.organization.github_organization.login }
  end

  define_type AssignmentInvitation.includes(:assignment) do
    field :id
    field :key
    field :created_at
    field :updated_at

    field :assignment_title, value: ->(assignment_invitation) { assignment_invitation.assignment.title }
  end

  define_type AssignmentRepo.includes(:assignment, :repo_access, :user) do
    field :id
    field :github_repo_id
    field :created_at
    field :updated_at

    field :assignment_title, value: ->(assignment_repo) { assignment_repo.assignment.title }
    field :user_login,       value: ->(assignment_repo) { assignment_repo.user.github_user.login }
  end

  define_type Deadline do
    field :id
    field :deadline_at
    field :created_at
    field :updated_at
  end

  define_type Group.includes(:organization) do
    field :id
    field :title
    field :github_team_id
    field :created_at
    field :updated_at

    field :organization_login, value: ->(group) { group.organization.github_organization.login }
  end

  define_type GroupAssignment.includes(:organization) do
    field :id
    field :slug
    field :title
    field :created_at
    field :updated_at

    field :organization_login, value: ->(group_assignment) { group_assignment.organization.github_organization.login }
  end

  define_type GroupAssignmentInvitation.includes(:group_assignment) do
    field :id
    field :key
    field :created_at
    field :updated_at

    field :group_assignment_title, value: (lambda do |group_assignment_invitation|
      group_assignment_invitation.group_assignment.title
    end)
  end

  define_type GroupAssignmentRepo.includes(:group_assignment, :group) do
    field :id
    field :github_repo_id
    field :created_at
    field :updated_at

    field :group_assignment_title, value: ->(group_assignment_repo) { group_assignment_repo.group_assignment.title }
    field :group_title,            value: ->(group_assignment_repo) { group_assignment_repo.group.title            }
  end

  define_type Grouping.includes(:organization) do
    field :title
    field :created_at
    field :updated_at

    field :organization_login, value: ->(grouping) { grouping.organization.github_organization.login }
  end

  define_type RepoAccess.includes(:organization, :user) do
    field :id
    field :created_at
    field :updated_at

    field :organization_login, value: ->(repo_access) { repo_access.organization.github_organization.login }
    field :user_login,         value: ->(repo_access) { repo_access.user.github_user.login                 }
  end

  define_type Organization do
    field :id
    field :github_id
    field :slug
    field :title
    field :created_at
    field :updated_at

    field :login, value: ->(organization) { organization.github_organization.login }
    field :name,  value: ->(organization) { organization.github_organization.name  }
  end

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
