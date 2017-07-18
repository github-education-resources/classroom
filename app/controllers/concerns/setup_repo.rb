# frozen_string_literal: true

module SetupRepo
  extend ActiveSupport::Concern
  IMPORT_IN_PROGRESS     = 'Importing starter code to student repo'
  CONFIGURATION_PROGRESS = 'Configuring the student repo'

  def setup_status(repo, config)
    progress = { status: 'importing', message: IMPORT_IN_PROGRESS }

    progress.update(status: 'configuring', message: CONFIGURATION_PROGRESS) if config.configurable? repo
    progress.update(status: 'complete') if config.configured? repo
    progress
  end

  def perform_setup(assignment_repo, config)
    assignment_repo.destroy! unless config.setup_repository(assignment_repo.github_repository)
  end
end
