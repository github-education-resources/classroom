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
      @client.organization_memberships(state: 'active').keep_if { |membership| membership.role == 'admin' }
    end
  end

  # Public
  #
  def user
    with_error_handling { @client.user(@id) }
  end
end
