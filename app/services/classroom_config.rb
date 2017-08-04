# frozen_string_literal: true

class ClassroomConfig
  CONFIGURABLES       = %w[issues labels].freeze
  CONFIG_BRANCH       = "github-classroom"
  CONFIG_PRIORITY     = { "labels" => 0, "issues" => 1 }.freeze

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
    configs = @github_repository.tree_objects(config_branch_sha)
    ordered_configs(configs).each do |config|
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
      blob = formated_blob(@github_repository.blob(issue.sha))
      next if blob.title.blank?
      repo.create_issue(blob.title, blob.body, labels: (blob.labels || []))
    end
  end

  # Internal: Generates labels for the assignment_repository based on the configs
  #
  # repo - GitHubRepository for which to perform the configuration
  #                   setups
  # tree_sha     - sha of the "labels" tree
  #
  # Returns nothing
  def generate_labels(repo, tree_sha)
    delete_existing_labels(repo)
    @github_repository.tree_objects(tree_sha).each do |label|
      blob = formated_blob(@github_repository.blob(label.sha))

      repo.create_label(blob.label, blob.color || GitHubRepository::DEFAULT_LABEL_COLOR) if blob.label.present?
    end
  end

  # Internal: Delete existing labels of a GitHubRepository
  #
  # repo - GitHubRepository
  #
  # Returns nothing
  def delete_existing_labels(repo)
    repo.labels.each do |label|
      repo.delete_label! label[:name]
    end
  end

  # Internal: Makes blob direct and data attributes accessible as method calls
  #
  # blob     - GitHubBlob to format
  #
  # Returns an OpenStruct of formated_blob instance
  def formated_blob(blob)
    fmt_blob = OpenStruct.new(body: blob.body, encoding: blob.encoding)
    return fmt_blob if blob.data.blank?
    blob.data.each do |k, v|
      fmt_blob[k] = v
    end
    fmt_blob
  end

  # Internal: Sort the configs to be ordered by priority
  #
  # configs - The list of configs to sort
  #
  # Returns a list of configs
  def ordered_configs(configs)
    configs.sort_by { |a| CONFIG_PRIORITY[a.path] }
  end
end
