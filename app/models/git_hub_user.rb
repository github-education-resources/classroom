class GitHubUser
  include GitHub

  def initialize(client, id = nil)
    @client = client
    @id     = id
  end

  # Public
  #
  def login
    with_error_handling { @client.user(@id).login }
  end

  # Public
  #
  def admin_organization_memberships
    with_error_handling do
      @client.organization_memberships(state: 'active', headers: no_cache_headers).keep_if do |membership|
        membership.role == 'admin'
      end
    end
  end

  # Public
  #
  def user
    with_error_handling { @client.user(@id) }
  end
end
