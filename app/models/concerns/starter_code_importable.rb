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

  def use_template_repos?
    starter_code? && template_repos_enabled?
  end

  def use_importer?
    starter_code? && !template_repos_enabled?
  end

  def starter_code_repository_is_template
    return unless use_template_repos?

    return if starter_code_repository.template?

    make_starter_repo_a_template!
  end

  private

  def make_starter_repo_a_template!
    GitHub::Errors.with_error_handling do
      creator.github_client.edit_repository(starter_code_repository.full_name, is_template: true)
    end
  rescue GitHub::Error
    errors.add(
      :starter_code_repository,
      "is not a template repository and we could not change the setting on your behalf. Repository must be a template "\
      "repository to use template cloning."
    )
  end
end
