class GitHubOrganization
  class Error     < StandardError; end
  class Forbidden < StandardError; end

  def initialize(client, github_id)
    @client    = client
    @github_id = github_id
  end

  # Public
  #
  def create_team(team_name)
    github_team = with_error_handling do
      @client.create_team(@github_id, name: team_name, permission: 'push')
    end

    GitHubTeam.new(@client, github_team.id, github_team.name)
  end

  # Public
  #
  def info
    with_error_handling { @client.organization(@github_id) }
  end

  # Public
  #
  def authorization_on_github_organization?(organization_login)
    with_error_handling do
      if @client.organization_membership(organization_login).role != 'admin'
        raise GitHubOrganization::Forbidden.new
      end
    end
  end

  # Internal
  #
  def build_error_message(errors)
    code     = errors[:code].gsub('_', ' ')
    resource = errors[:resource]
    field    = errors[:field]

    "#{resource} #{field} #{code}"
  end

  # Internal
  #
  def with_error_handling
    yield
  rescue Octokit::Error => err
    case err
    when Octokit::Forbidden
      raise GitHubOrganization::Forbidden.new

    when Octokit::NotFound
      raise GitHubOrganization::Forbidden.new

    when Octokit::ServerError
      raise GitHubOrganization::Error.new

    when Octokit::UnprocessableEntity
      error_message = build_error_message(err.errors.first)
      raise GitHubOrganization::Error.new(message: error_message)
    end
  end
end
