# frozen_string_literal: true

class GitHubTeam < GitHubResource
  def add_team_membership(new_user_github_login)
    GitHub::Errors.with_error_handling do
      @client.add_team_membership(@id, new_user_github_login)
    end
  end

  def remove_team_membership(user_github_login)
    GitHub::Errors.with_error_handling do
      @client.remove_team_membership(@id, user_github_login)
    end
  end

  def add_team_repository(full_name, options = {})
    GitHub::Errors.with_error_handling do
      unless @client.add_team_repository(@id, full_name, options)
        raise GitHub::Error, "Could not add team to the GitHub repository"
      end
    end
  end

  def team_repository?(full_name)
    GitHub::Errors.with_error_handling do
      @client.team_repository?(@id, full_name)
    end
  end

  def html_url
    "https://github.com/orgs/#{github_organization.login}/teams/#{slug}"
  end

  def github_organization
    @github_organization ||= GitHubOrganization.new(@client, organization.id)
  end

  private

  def github_attributes
    %w[slug name organization]
  end
end
