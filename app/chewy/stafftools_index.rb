# rubocop:disable Metrics/ClassLength
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
    field :id
    field :slug
    field :github_id
    field :created_at
    field :updated_at

    field :avatar_url, value: (lambda do |org|
      begin
        GitHubOrganization.new(org.github_client, org.github_id).organization.avatar_url
      rescue GitHub::Forbidden, GitHub::NotFound
        "https://avatars.githubusercontent.com/u/#{org.github_id}?v=3"
      end
    end)

    field :html_url, value: (lambda do |org|
      begin
        GitHubOrganization.new(org.github_client, org.github_id).organization.html_url
      rescue GitHub::Forbidden, GitHub::NotFound
        NullGitHubOrganization.new.html_url
      end
    end)

    field :login, value: (lambda do |org|
      begin
        GitHubOrganization.new(org.github_client, org.github_id).organization.login
      rescue GitHub::Forbidden, GitHub::NotFound
        NullGitHubOrganization.new.login
      end
    end)

    field :name, value: (lambda do |org|
      begin
        GitHubOrganization.new(org.github_client, org.github_id).organization.name
      rescue GitHub::Forbidden, GitHub::NotFound
        NullGitHubOrganization.new.name
      end
    end)
  end

  define_type User do
    field :id
    field :uid
    field :created_at
    field :updated_at

    field :avatar_url, value: (lambda do |user|
      begin
        GitHubUser.new(user.github_client, user.uid).user.avatar_url
      rescue GitHub::Forbidden, GitHub::NotFound
        "https://avatars.githubusercontent.com/u/#{user.uid}?v=3"
      end
    end)

    field :html_url, value: (lambda do |user|
      begin
        GitHubUser.new(user.github_client, user.uid).user.html_url
      rescue GitHub::Forbidden, GitHub::NotFound
        NullGitHubUser.new.html_url
      end
    end)

    field :login, value: (lambda do |user|
      begin
        GitHubUser.new(user.github_client, user.uid).login
      rescue GitHub::Forbidden, GitHub::NotFound
        NullGitHubUser.new.login
      end
    end)

    field :name, value: (lambda do |user|
      begin
        GitHubUser.new(user.github_client, user.uid).user.name
      rescue GitHub::Forbidden, GitHub::NotFound
        NullGitHubUser.new.name
      end
    end)
  end
end
# rubocop:enable Metrics/ClassLength
