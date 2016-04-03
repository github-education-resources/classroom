class StafftoolsIndex < Chewy::Index
  define_type Assignment do
    field :id
    field :slug
    field :title
    field :created_at
    field :updated_at

    field :organization_login, value: ->(assignment) { assignment.github_organization.login }
  end

  define_type AssignmentInvitation do
    field :id
    field :key
    field :created_at
    field :updated_at

    field :assignment_title, value: ->(assignment_invitation) { assignment_invitation.assignment.title }
  end

  define_type AssignmentRepo do
    field :id
    field :github_repo_id
    field :created_at
    field :updated_at

    field :assignment_title, value: ->(assignment_repo)  { assignment_repo.assignment.title  }
    field :user_login,       value: ->(assignment_repo)  { assignment_repo.github_user.login }
  end

  define_type Group do
    field :id
    field :title
    field :github_team_id
    field :created_at
    field :updated_at

    field :organization_login, value: ->(group) { group.github_organization.login }
  end

  define_type GroupAssignment do
    field :id
    field :slug
    field :title
    field :created_at
    field :updated_at

    field :organization_login, value: ->(group_assignment) { group_assignment.github_organization.login }
  end

  define_type GroupAssignmentInvitation do
    field :id
    field :key
    field :created_at
    field :updated_at

    field :group_assignment_title, value: (lambda do |group_assignment_invitation|
      group_assignment_invitation.group_assignment.title
    end)
  end

  define_type GroupAssignmentRepo do
    field :id
    field :github_repo_id
    field :created_at
    field :updated_at

    field :group_assignment_title, value: ->(group_assignment_repo) { group_assignment_repo.group_assignment.title  }
    field :group_title,            value: ->(group_assignment_repo) { group_assignment_repo.group.title             }
  end

  define_type Grouping do
    field :title
    field :created_at
    field :updated_at

    field :organization_login, value: ->(github_organization) { github_organization.login }
  end

  define_type RepoAccess do
    field :id
    field :created_at
    field :updated_at

    field :organization_login, value: ->(repo_access) { repo_access.github_organization.login }
    field :user_login,         value: ->(repo_access) { repo_access.github_user.login         }
  end

  define_type Organization do
    field :id
    field :github_id
    field :slug
    field :title
    field :created_at
    field :updated_at

    field :login, value: ->(organization) { organization.github_organization.login }
    field :name,  value: (lambda do |organization|
      organization.github_organization.name || organization.github_organization.login
    end)
  end

  define_type User do
    field :id
    field :uid
    field :created_at
    field :updated_at

    field :login, value: ->(user) { user.github_user.login                          }
    field :name,  value: ->(user) { user.github_user.name || user.github_user.login }
  end
end
