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

  def starter_code_repository_not_empty
    return unless starter_code? && starter_code_repository.empty?
    errors.add :starter_code_repository, "cannot be empty. Select a repository that is not empty or create the"\
      " assignment without starter code."
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
    errors.add(
      :starter_code_repository,
      "is not a template repository. Make it a template repository to use template cloning."
    )
  end

  private

  def track_private_repo_belonging_to_user
    return unless starter_code_repository
    return unless starter_code_repository.private && starter_code_repository.owner[:type] == "User"
    GitHubClassroom.statsd.increment("assignment.private_repo_owned_by_user.create")
  end
end
