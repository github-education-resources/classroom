class GithubClient
  def initialize(token)
    @token = token
  end

  def add_team_membership(team_id, login)
    client.add_team_membership(team_id, login)
  end

  def create_team(github_id, options = {})
    client.create_team(github_id, options)
  end

  def organization_admin?(github_id)
    organization_login = client.organization(github_id.to_i).login
    begin
      client.organization_membership(organization_login).role == "admin"
    rescue Octokit::NotFound
      false
    end
  end

  def organization(github_id)
    client.organization(github_id)
  end

  def organization_teams(github_id)
    client.organization_teams(github_id.to_i)
  end

  def team(github_id)
    client.team(github_id)
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
