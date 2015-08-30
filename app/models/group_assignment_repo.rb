class GroupAssignmentRepo < ActiveRecord::Base
  include GitHubRepoable

  has_one :organization, -> { unscope(where: :deleted_at) }, through: :group_assignment

  has_many :repo_accesses, through: :group

  belongs_to :group
  belongs_to :group_assignment

  validates :github_repo_id, presence:   true
  validates :github_repo_id, uniqueness: true

  validates :group_assignment, presence: true

  validates :group, presence: true
  validates :group, uniqueness: { scope: :group_assignment }

  # Public
  #
  def creator
    group_assignment.creator
  end

  # Public
  #
  def private?
    !group_assignment.public_repo?
  end

  # Public
  #
  def github_team_id
    group.github_team_id
  end

  private

  # Internal
  #
  def repo_name
    "#{group_assignment.title}-#{group.title}"
  end

  # Internal
  #
  def starter_code_repo_id
    group_assignment.starter_code_repo_id
  end
end
