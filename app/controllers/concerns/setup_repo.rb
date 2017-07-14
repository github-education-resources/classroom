# frozen_string_literal: true

module SetupRepo
  extend ActiveSupport::Concern
  IMPORT_IN_PROGRESS     = 'Importing starter code to student repo'
  CONFIGURATION_PROGRESS = 'Configuring the student repo'

  def setup_status(repo, config)
    progress = { status: 'importing', message: IMPORT_IN_PROGRESS }

    return progress unless repo.import_progress[:status] == 'complete'

    progress.update(status: 'complete') unless config.github_repository.branch_present? 'github-classroom'
    progress.update(status: 'configuring', message: CONFIGURATION_PROGRESS) if repo.branch_present? 'github-classroom'
    progress.update(status: 'complete') unless config.finished_setup? repo
    progress
  end

  def perform_setup(repo, config)
    config.setup_repository(repo)
    return true
  rescue GitHub::Error
    return false
  end
end
