# frozen_string_literal: true

module RepoSetup
  extend ActiveSupport::Concern

  def setup_status(assignment_repo)
    repo     = assignment_repo.github_repository
    progress = { status: :importing }

    return progress unless repo.imported?

    progress.update(status: :configuring) if assignment_repo.configuring?
    progress.update(status: :complete) if assignment_repo.configured?
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

  def config_branch
    ClassroomConfig::CONFIG_BRANCH
  end
end
