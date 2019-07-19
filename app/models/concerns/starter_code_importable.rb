# frozen_string_literal: true

module StarterCodeImportable
  GITHUB_API_HOST = "https://api.github.com"
  TEMPLATE_REPOS_API_PREVIEW = "application/vnd.github.baptiste-preview"

  extend ActiveSupport::Concern

  def starter_code?
    starter_code_repo_id.present?
  end

  def starter_code_repository
    return unless starter_code?
    @starter_code_repository ||= GitHubRepository.new(creator.github_client, starter_code_repo_id)
  end

  def use_template_repos?
    starter_code? && template_repos_enabled?
  end

  def use_importer?
    starter_code? && !template_repos_enabled?
  end

  def starter_code_repository_is_template
    return unless use_template_repos?

    return if starter_code_repository.template?

    make_starter_code_repository_a_template!
  end

  private

  # rubocop:disable Metrics/MethodLength
  def make_starter_code_repository_a_template!
    options = { accept: TEMPLATE_REPOS_API_PREVIEW, is_template: true }
    endpoint_url = "#{GITHUB_API_HOST}/repositories/#{starter_code_repo_id}"

    GitHub::Errors.with_error_handling do
      creator.github_client.patch(endpoint_url, options)
    end
  rescue GitHub::Error
    errors.add(
      :starter_code_repository,
      "is not a template and we could not change the settings on your behalf. Repository must be a template "\
        "repository to use template cloning."
    )
  end
end
