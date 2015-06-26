class GitHubClient
  def initialize(token)
    @token = token
  end

  def add_team_membership(team_id, login)
    client.add_team_membership(team_id, login)
  end

  def create_repository(name, options = {})
    client.create_repository(name, options)
  rescue
    nil
  end

  def create_team(org_github_id, options = {})
    client.create_team(org_github_id, options)
  rescue
    nil
  end

  def organization(github_id)
    client.organization(github_id)
  end

  def organization_admin?(github_id)
    organization_login = client.organization(github_id.to_i).login
    begin
      organization_membership(organization_login).role == 'admin'
    rescue
      false
    end
  end

  def organization_membership(github_login)
    client.organization_membership(github_login)
  end

  def organization_memberships
    client.organization_memberships(headers: { 'Cache-Control' => 'no-cache, no-store' })
  end

  def organization_teams(github_id)
    client.organization_teams(github_id.to_i)
  end

  def repository(github_id)
    client.repository(github_id)
  end

  def team(github_team_id)
    client.team(github_team_id)
  rescue
    nil
  end

  def team_repository?(team_id, full_repo_name)
    client.team_repository?(team_id, full_repo_name)
  end

  def user(github_id = nil)
    client.user(github_id)
  end

  private

  def client
    @client ||= Octokit::Client.new(access_token: @token,
                                    auto_paginate:  true)
  end
end
