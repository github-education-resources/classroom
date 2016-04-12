module GitHubPlan
  extend ActiveSupport::Concern

  delegate :github_organization, to: :organization

  included do
    before_validation(on: :create) do
      verify_organization_has_private_repos_available if private?
    end
  end

  def verify_organization_has_private_repos_available
    owned_private_repos = github_organization.plan[:owned_private_repos]
    private_repos       = github_organization.plan[:private_repos]

    return if owned_private_repos < private_repos

    error_message = <<-ERROR
    Cannot make this private assignment, your limit of #{private_repos}
    #{'repository'.pluralize(private_repos)} has been reached. You can request
    a larger plan for free at https://education.github.com/discount
    ERROR

    raise GitHub::Error, error_message
  end
end
