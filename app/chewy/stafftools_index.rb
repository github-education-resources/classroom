class StafftoolsIndex < Chewy::Index
  define_type Assignment do
    field :id
    field :slug
    field :title
    field :created_at
    field :updated_at
  end

  define_type AssignmentInvitation do
    field :id
    field :key
    field :created_at
    field :updated_at
  end

  define_type AssignmentRepo do
    field :id
    field :github_repo_id
    field :created_at
    field :updated_at
  end

  define_type Group do
    field :id
    field :title
    field :github_team_id
    field :created_at
    field :updated_at
  end

  define_type GroupAssignment do
    field :id
    field :slug
    field :title
    field :created_at
    field :updated_at
  end

  define_type GroupAssignmentInvitation do
    field :id
    field :key
    field :created_at
    field :updated_at
  end

  define_type GroupAssignmentRepo do
    field :id
    field :github_repo_id
    field :created_at
    field :updated_at
  end

  define_type Grouping do
    field :title
    field :created_at
    field :updated_at
  end

  define_type RepoAccess do
    field :id
    field :created_at
    field :updated_at
  end

  define_type Organization do
    include GitHub

    field :id
    field :slug
    field :github_id
    field :created_at
    field :updated_at

    field :login, value: (lambda do |org|
      begin
        begin
          GitHubOrganization.new(org.github_client, org.github_id).organization.login
        rescue GitHub::Forbidden
          GitHubOrganization.new(application_github_client, org.github_id).organization.login
        end
      rescue GitHub::NotFound
        NullGitHubOrganization.new.login
      end
    end)

    field :name, value: (lambda do |org|
      begin
        begin
          GitHubOrganization.new(org.github_client, org.github_id).organization.name
        rescue GitHub::Forbidden
          GitHubOrganization.new(application_github_client, org.github_id).organization.name
        end
      rescue GitHub::NotFound
        NullGitHubOrganization.new.name
      end
    end)
  end

  define_type User do
    include GitHub

    field :id
    field :uid
    field :created_at
    field :updated_at

    field :login, value: (lambda do |user|
      begin
        begin
          GitHubUser.new(user.github_client, user.uid).user.login
        rescue GitHub::Forbidden
          GitHubUser.new(application_github_client, user.uid).user.login
        end
      rescue GitHub::NotFound
        NullGitHubUser.new.login
      end
    end)

    field :name, value: (lambda do |user|
      begin
        begin
          GitHubUser.new(user.github_client, user.uid).user.name
        rescue GitHub::Forbidden
          GitHubUser.new(application_github_client, user.uid).user.name
        end
      rescue GitHub::NotFound
        NullGitHubUser.new.name
      end
    end)
  end
end
