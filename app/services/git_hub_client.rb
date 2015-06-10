class GitHubClient
  def initialize(token)
    @token = token
  end

  def add_team_membership(team_id, login)
    client.add_team_membership(team_id, login)
  end

  def add_team_repository(team_id, repo_id, options = {})
    client.add_team_repository(team_id, repo_id, options)
  end

  def create_repository(name, options = {})
    begin
      client.create_repository(name, options)
    rescue
      nil
    end
  end

  def create_team(org_github_id, options = {})
    begin
      client.create_team(org_github_id, options)
    rescue
      nil
    end
  end

  def organization(github_id)
    client.organization(github_id)
  end

  def organization_admin?(github_id)
    organization_login = client.organization(github_id.to_i).login
    begin
      organization_membership(organization_login).role == "admin"
    rescue
      false
    end
  end

  def organization_membership(github_login)
    client.organization_membership(github_login)
  end

  def organization_teams(github_id)
    client.organization_teams(github_id.to_i)
  end

  def repository(github_id)
    client.repository(github_id)
  end

  def team(github_team_id)
    begin
      client.team(github_team_id)
    rescue
      nil
    end
  end

  def update_team(team_id, options)
    client.update_team(team_id, options)
  end

  def user(github_id=nil)
    client.user(github_id)
  end

  def users_organizations
    client.list_organizations
  end

  private

  def client
    @client ||= Octokit::Client.new(access_token: @token,
                                    auto_paginate:  true)
  end
end
