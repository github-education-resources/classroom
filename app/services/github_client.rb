class GithubClient
  def initialize(login, token)
    @login = login
    @token = token
  end

  def is_organization_admin?(org)
    client.organization_membership(org).role == "admin"
  end

  def organization(org)
    client.organization(org)
  end

  def users_organizations
    client.list_organizations(@login)
  end

  private

  def client
    @client ||= Octokit::Client.new(login:         @login,
                                    access_token:  @token,
                                    auto_paginate: true)
  end
end
