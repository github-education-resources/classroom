class AssignmentRepo < ActiveRecord::Base
  include GitHubRepoable

  has_one :organization, through: :assignment

  belongs_to :assignment
  belongs_to :repo_access

  validates :assignment, presence: true

  validates :github_repo_id, presence:   true
  validates :github_repo_id, uniqueness: true

  validates :repo_access, presence:   true
  validates :repo_access, uniqueness: { scope: :assignment }

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

  private

  # Internal
  #
  def github_team_id
    repo_access.github_team_id
  end

  # Internal
  #
  def repo_name
    "#{assignment.title}-#{assignment.assignment_repos.count + 1}"
  end

  # Internal
  #
  def starter_code_repo_id
    assignment.starter_code_repo_id
  end
end
