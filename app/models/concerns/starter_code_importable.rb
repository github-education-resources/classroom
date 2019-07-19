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

    options = { accept: TEMPLATE_REPOS_API_PREVIEW }
    endpoint_url = "#{GITHUB_API_HOST}/repositories/#{starter_code_repo_id}"
    starter_code_github_repository = creator.github_client.get(endpoint_url, options)

    return if starter_code_github_repository.is_template
    errors.add(
      :starter_code_repository,
      "is not a template repository. Make it a template repository to use template cloning."
    )
  end
end
