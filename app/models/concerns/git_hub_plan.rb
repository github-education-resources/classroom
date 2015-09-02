module GitHubPlan
  extend ActiveSupport::Concern

  included do
    before_validation(on: :create) do
      verify_organization_has_private_repos_available if private?
    end
  end

  def verify_organization_has_private_repos_available
    created_private_repos = github_assignment_organization.owned_private_repos
    allowed_private_repos = github_assignment_organization.plan.private_repos

    return if created_private_repos < allowed_private_repos

    error_message = <<-ERROR
    Cannot make this private assignment, your limit of #{allowed_private_repos}
    #{'repository'.pluralize(allowed_private_repos)} has been reached
    ERROR

    fail ActiveRecord::RecordInvalid.new(self), error_message
  end

  def github_assignment_organization
    @github_assignment_organization = GitHubOrganization.new(organization.github_client,
                                                             organization.github_id).organization
  end
end
