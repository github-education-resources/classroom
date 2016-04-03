class AssignmentRepo < ActiveRecord::Base
  include GitHubPlan
  include GitHubRepoable

  update_index('stafftools#assignment_repo') { self }

  has_one :organization, -> { unscope(where: :deleted_at) }, through: :assignment

  belongs_to :assignment
  belongs_to :repo_access
  belongs_to :user

  validates :assignment, presence: true

  validates :github_repo_id, presence:   true
  validates :github_repo_id, uniqueness: true

  before_destroy :silently_destroy_github_repository

  # Public
  #
  def setup_github_repository
    if organization.present?
      # unless github_repository
      #   create_github_repository
      #   push_starter_code
      # end
      create_github_repository
      push_starter_code
      add_user_as_collaborator
    end
  end

  # Public
  #
  def set_repo_name_suffix(repo_name_suffix)
    @repo_name_suffix = repo_name_suffix
  end


  # Public
  #
  def creator
    assignment.creator
  end

  # Public
  #
  def private?
    !assignment.public_repo?
  end

  # Public
  #
  def github_team_id
    repo_access.present? ? repo_access.github_team_id : nil
  end

  # Public
  #
  def repo_name
    github_user = GitHubUser.new(user.github_client, user.uid)
    return "#{assignment.slug}-#{github_user.login(headers: GitHub::APIHeaders.no_cache_no_store)}" unless @repo_name_suffix.present?
    "#{assignment.slug}-#{github_user.login(headers: GitHub::APIHeaders.no_cache_no_store)}-#{@repo_name_suffix}"
  end

  # Public
  #
  def starter_code_repo_id
    assignment.starter_code_repo_id
  end
end
