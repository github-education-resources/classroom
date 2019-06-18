# frozen_string_literal: true

module GitHubRepoable
  extend ActiveSupport::Concern

  # Public
  #
  def destroy_github_repository
    github_organization.delete_repository(github_repo_id)
  end

  # Public
  #
  def delete_github_repository_on_failure
    yield
  rescue GitHub::Error => error
    silently_destroy_github_repository
    raise GitHub::Error, "Assignment failed to be created: #{error}"
  end

  # Public
  #
  def silently_destroy_github_repository
    destroy_github_repository
    true # Destroy ActiveRecord object even if we fail to delete the repository
  end

  # Internal
  #
  def github_organization
    @github_organization ||= GitHubOrganization.new(organization.github_client, organization.github_id)
  end

end
