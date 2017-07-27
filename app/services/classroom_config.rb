# frozen_string_literal: true

class ClassroomConfig
  CONFIGURABLES   = %w[issues].freeze
  CONFIGBRANCH    = "github-classroom"

  attr_reader :github_repository

  def initialize(github_repository)
    raise ArgumentError, "Invalid configuration repo" unless github_repository.branch_present? CONFIGBRANCH
    @github_repository = github_repository
  end

  # Public: Setup a GitHub Repository based on classroom configurations
  #
  # repo - A GitHubRepository instance for which to perform the configuration
  #                   setups
  #
  # Returns true when setup is successful false otherwise
  def setup_repository(repo)
    configs_tree = @github_repository.branch_tree(CONFIGBRANCH)
    configs_tree.tree.each do |config|
      send("generate_#{config.path}", repo, config.sha) if CONFIGURABLES.include? config.path
    end

    repo.remove_branch(CONFIGBRANCH)
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
    repo.branch_present?(CONFIGBRANCH)
  end

  # Public: Check if a GitHubRepository is already configured
  #
  # repo - A GitHubRepository instance
  #
  # Returns true or false
  def configured?(repo)
    !configurable?(repo) && repo.import_progress[:status] == "complete"
  end

  private

  # Internal: Generates issues for the assignment_repository based on the configs
  #
  # repo - GitHubRepository for which to perform the configuration
  #                   setups
  # tree_sha     - sha of the "issues" tree
  #
  # Returns nothing
  def generate_issues(repo, tree_sha)
    @github_repository.tree(tree_sha).tree.each do |issue|
      blob = @github_repository.blob(issue.sha)
      repo.create_issue(blob.data["title"], blob.body) if blob.data.present?
    end
  end
end
