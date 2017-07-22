# frozen_string_literal: true

module SetupRepo
  extend ActiveSupport::Concern

  def setup_status(assignment_repo)
    repo     = assignment_repo.github_repository
    progress = { status: :importing }

    return progress unless repo.import_progress[:status] == "complete"

    progress.update(status: :configuring) if assignment_repo.configuring?
    progress.update(status: :complete) if assignment_repo.configured? || !repo.branch_present?("github-classroom")
    progress
  end

  def perform_setup(assignment_repo, config)
    assignment_repo.configuring!
    if config.setup_repository(assignment_repo.github_repository)
      assignment_repo.configured!
    else
      assignment_repo.destroy!
    end
  end
end
