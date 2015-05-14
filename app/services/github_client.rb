class GithubClient
  def initialize(login, token)
    @login = login
    @token = token
  end

  def is_organization_owner?(org_id)
    owners_team_id = client.organization_teams(org_id).first.id
    client.team_member?(owners_team_id, @login)
  end

  def organization(org, options = {})
    client.organization(org, options)
  end

  def users_organizations
    client.organizations(@login)
  end

  private

  def client
    @client ||= Octokit::Client.new(login:         @login,
                                    access_token:  @token,
                                    auto_paginate: true)
  end
end
