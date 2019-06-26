# frozen_string_literal: true

module AssignmentRepoable
  extend ActiveSupport::Concern

  included do
    validates :github_repo_id, presence:   true
    validates :github_repo_id, uniqueness: true

    before_destroy :silently_destroy_github_repository
  end

  def private?
    !assignment.public_repo?
  end

  def github_repository
    @github_repository ||= GitHubRepository.new(organization.github_client, github_repo_id)
  end

  def import_status
    return "No starter code provided" unless assignment.starter_code?

    github_repository.import_progress.status.humanize
  end

  # Internal: Attempt to destroy the GitHub repository.
  #
  # Returns true.
  def silently_destroy_github_repository
    return true if organization.blank?

    organization.github_organization.delete_repository(github_repo_id)
    true
  rescue GitHub::Error
    true
  end
end
