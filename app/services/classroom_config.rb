# frozen_string_literal: true

class ClassroomConfig
  CONFIGURABLES   = %w[issues].freeze
  CONFIG_BRANCH   = "github-classroom"

  attr_reader :github_repository

  def initialize(github_repository)
    raise ArgumentError, "Invalid configuration repo" unless github_repository.branch_present? CONFIG_BRANCH
    @github_repository = github_repository
  end

  # Public: Setup a GitHub Repository based on classroom configurations
  #
  # repo - A GitHubRepository instance for which to perform the configuration
  #                   setups
  #
  # Returns true when setup is successful false otherwise
  def setup_repository(repo)
    config_branch_sha = @github_repository.branch(CONFIG_BRANCH).commit.sha
    @github_repository.tree_objects(config_branch_sha).each do |config|
      send("generate_#{config.path}", repo, config.sha) if CONFIGURABLES.include? config.path
    end

    repo.remove_branch(CONFIG_BRANCH)
    true
  rescue GitHub::Error
    false
  end

  # Public: Check if a GitHubRepository can be configured
  #
  # repo - A GitHubRepository instance
  #
  # Returns true or false
  def configurable?(repo)
    repo.branch_present?(CONFIG_BRANCH)
  end

  private

  # Internal: Generates issues for the assignment_repository based on the configs
  #
  # tree_sha     - sha of the "issues" tree
  #
  # Returns nothing
  def generate_issues(repo, tree_sha)
    @github_repository.tree_objects(tree_sha).each do |issue|
      blob = @github_repository.blob(issue.sha)
      repo.create_issue(blob.data["title"], blob.body) if blob.data.present?
    end
  end
end
