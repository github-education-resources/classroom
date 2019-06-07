# frozen_string_literal: true

module GitHubPlan
  extend ActiveSupport::Concern

  included do
    before_validation do
      verify_organization_has_private_repos_available if private?
    end
  end

  # rubocop:disable MethodLength
  def verify_organization_has_private_repos_available
    github_organization_plan = GitHubOrganization.new(organization.github_client, organization.github_id).plan

    owned_private_repos = github_organization_plan[:owned_private_repos]
    private_repos       = github_organization_plan[:private_repos]

    return if owned_private_repos < private_repos

    error_message = <<-ERROR
    Cannot make a private repository for this assignment, the organization has
    a limit of #{private_repos} #{'repository'.pluralize(private_repos)}.
    Please let the organization owner know that they can either upgrade their
    limit or, if the owner qualifies, request a larger plan for free at
    <a href='https://education.github.com/discount'>https://education.github.com/discount</a>
    ERROR

    raise GitHub::Error, error_message
  end
  # rubocop:enable MethodLength
end
