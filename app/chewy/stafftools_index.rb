# rubocop:disable ClassLength
class StafftoolsIndex < Chewy::Index
  define_type Assignment do
    field :id
    field :slug
    field :title
    field :created_at
    field :updated_at

    field :organization_login, value: (lambda do |assignment|
      org = assignment.organization

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

    field :assignment_title, value: ->(assignment_invitation) { assignment_invitation.assignment.title }

    field :user_login, value: (lambda do |assignment_repo|
      user = assignment_repo.user

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
  end

  define_type Group do
    field :id
    field :title
    field :github_team_id
    field :created_at
    field :updated_at

    field :organization_login, value: (lambda do |group_assignment|
      org = group_assignment.organization

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
  end

  define_type GroupAssignment do
    field :id
    field :slug
    field :title
    field :created_at
    field :updated_at

    field :organization_login, value: (lambda do |group_assignment|
      org = group_assignment.organization

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

    field :group_assignment_title, value: (lambda do |group_assignment_repo|
      group_assignment_repo.group_assignment.title
    end)

    field :group_title, value: ->(group_assignment_repo) { group_assignment_repo.group.title }
  end

  define_type Grouping do
    field :title
    field :created_at
    field :updated_at

    field :organization_login, value: (lambda do |repo_access|
      org = repo_access.organization

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
  end

  define_type RepoAccess do
    field :id
    field :created_at
    field :updated_at

    field :organization_login, value: (lambda do |repo_access|
      org = repo_access.organization

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

    field :user_login, value: (lambda do |repo_access|
      user = repo_access.user

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
  end

  define_type Organization do
    field :id
    field :github_id
    field :slug
    field :title
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

  def self.application_github_client
    Octokit::Client.new(client_id: Rails.application.secrets.github_client_id,
                        client_secret: Rails.application.secrets.github_client_secret)
  end
end
# rubocop:enable ClassLength
