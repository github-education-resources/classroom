# frozen_string_literal: true

class NullGitHubTeam < NullGitHubResource
  def name
    "Deleted team"
  end

  def organization
    NullGitHubOrganization.new
  end

  def slug
    "ghost"
  end

  def html_url
    "https://github.com/orgs/ghost/teams/ghost"
  end

  def on_github?
    false
  end
end
