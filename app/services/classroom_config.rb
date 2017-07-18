# frozen_string_literal: true

class ClassroomConfig
  CONFIGURABLES = %w[issues].freeze

  attr_reader :github_repository

  def initialize(github_repository)
    raise ArgumentError, 'Invalid configuration repo' unless github_repository.branch_present? 'github-classroom'
    @github_repository = github_repository
  end

  def setup_repository(repo)
    configs_tree = @github_repository.branch_tree('github-classroom')
    GitHub::Errors.with_error_handling do
      configs_tree.tree.each do |config|
        send("generate_#{config.path}", repo, config.sha) if CONFIGURABLES.include? config.path
      end

      repo.remove_branch('github-classroom')
    end
  end

  def configurable?(repo)
    repo.branch_present?('github-classroom')
  end

  def configured?(repo)
    !configurable?(repo) && repo.import_progress[:status] == 'complete'
  end

  private

  # Internal: Generates issues for the assignment_repository based on the configs
  #
  # repo - GitHubRepository for which to perform the configuration
  #                   setups
  # tree_sha     - sha of the 'issues' tree
  #
  # Returns nothing
  def generate_issues(repo, tree_sha)
    GitHub::Errors.with_error_handling do
      @github_repository.tree(tree_sha).tree.each do |issue|
        blob = @github_repository.blob(issue.sha)
        repo.add_issue(blob.data['title'], blob.body) if blob.data.present?
      end
    end
  end
end
