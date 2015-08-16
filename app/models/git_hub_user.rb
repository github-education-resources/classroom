class GitHubUser
  include GitHub

  def initialize(client, id = nil)
    @client = client
    @id     = id
  end

  # Public: Get the GitHub Login that the client requests for
  # If the @id is nil, it will return the login the belongs to the
  # @client
  #
  # Returns the login as a String
  def login
    with_error_handling { @client.user(@id).login }
  end

  # Public: Get the Organizations that the client is an admin of
  #
  # Example
  #   github_user = GitHubUser.new(current_user.github_client)
  #   github_user.admin_organization_memberships
  #   # => [ [{:url=>"https://api.github.com/orgs/jazzkode/memberships/tarebyte",
  #     :state=>"active",
  #     :role=>"admin",
  #     :organization_url=>"https://api.github.com/orgs/jazzkode",
  #     :organization=>]
  #     ...
  #     ]
  #
  # Returns an Array of Hashes of GitHub Organization information
  def admin_organization_memberships
    with_error_handling do
      @client.organization_memberships(state: 'active', headers: no_cache_headers).keep_if do |membership|
        membership.role == 'admin'
      end
    end
  end

  # Public: Retrieve the Users GitHub information from the GitHub API
  #
  # Example
  #   github_user = GitHubUser.new(current_user.github_client)
  #   github_user.user
  #   # => {:login=>"tarebyte",
  #     :id=>564113,
  #     :avatar_url=>"https://avatars.githubusercontent.com/u/564113?v=3",
  #     :gravatar_id=>"",
  #     ...
  #     }
  #
  def user
    with_error_handling { @client.user(@id) }
  end
end
