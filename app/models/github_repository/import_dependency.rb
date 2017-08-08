# frozen_string_literal: true

class GitHubRepository
  IMPORT_ERRORS  = %w[auth_failed error detection_needs_auth detection_found_nothing detection_found_multiple].freeze
  IMPORT_ONGOING = %w[detecting importing mapping pushing].freeze

  def get_starter_code_from(source)
    GitHub::Errors.with_error_handling do
      options = {
        vcs:          "git",
        accept:       Octokit::Preview::PREVIEW_TYPES[:source_imports],
        vcs_username: @client.login,
        vcs_password: @client.access_token
      }

      @client.start_source_import(@id, "https://github.com/#{source.full_name}", options)
    end
  end

  def import_progress(**options)
    GitHub::Errors.with_error_handling do
      @client.source_import_progress(full_name, options)
    end
  end

  # Public: Check if importer is still importing
  #
  # Returns true or false
  def importing?
    IMPORT_ONGOING.include? import_progress[:status]
  end

  # Public: Check if import is complete
  #
  # Returns true or false
  def imported?
    import_progress[:status] == "complete"
  end

  # Public: Check if import failed
  #
  # Returns true or false
  def import_failed?
    IMPORT_ERRORS.include? import_progress[:status]
  end
end
