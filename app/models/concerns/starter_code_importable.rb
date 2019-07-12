# frozen_string_literal: true

module StarterCodeImportable
  extend ActiveSupport::Concern

  def starter_code?
    starter_code_repo_id.present?
  end

  def starter_code_repository
    return unless starter_code?
    @starter_code_repository ||= GitHubRepository.new(creator.github_client, starter_code_repo_id)
  end

  def template_repos_enabled?
    template_repos_enabled
  end

  def template_repos_disabled?
    !template_repos_enabled
  end

  def use_template_repos?
    starter_code? && template_repos_enabled?
  end

  def use_importer?
    starter_code? && template_repos_disabled?
  end

  def starter_code_repository_is_a_template_repository
    return unless use_template_repos?

    options = { accept: "application/vnd.github.baptiste-preview" }
    endpoint_url = "https://api.github.com/repositories/#{starter_code_repo_id}"
    starter_code_github_repository = creator.github_client.get(endpoint_url, options)

    return if starter_code_github_repository.is_template
    errors.add(
      :starter_code_repository,
      "is not a template repository. Make it a template repository to use template cloning."
    )
  end  
end
