class GitHubUser
  include GitHubable

  def initialize(client, id = nil)
    @client = client
    @id     = id
  end

  def authorized_access_token?
    with_error_handling do
      application_github_client.check_application_authorization(@client.access_token,
                                                                headers: no_cache_headers).present?
    end
  rescue GitHubable::NotFound
    false
  end

  def client_scopes
    with_error_handling { @client.scopes(@client.access_token, headers: no_cache_headers) }
  rescue GitHubable::Forbidden
    []
  end

  # Public
  #
  def login
    with_error_handling { @client.user(@id).login }
  end

  # Public
  #
  def organization_memberships
    with_error_handling do
      @client.organization_memberships(state: 'active', headers: no_cache_headers)
    end
  end

  # Public
  #
  def user
    with_error_handling { @client.user(@id) }
  end
end
