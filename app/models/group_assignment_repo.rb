class GroupAssignmentRepo < ActiveRecord::Base
  include GitHubPlan
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

  # Public: Get the parent group assignments creator
  # Returns the User that created the GroupAssignment
  def creator
    group_assignment.creator
  end

  # Public: Determine if the GroupAssignmentRepo's GroupAssignment is private
  #
  # Example
  #
  #  group_assignment_repo.private?
  #  # => true
  #
  # Returns a boolean
  def private?
    !group_assignment.public_repo?
  end

  # Public: Return the GitHub team id from GroupAssignmentRepos Group
  # Returns the GitHub Team id as an Integer
  def github_team_id
    group.github_team_id
  end

  # Public: Build the title for the GroupAssignmentRepo
  # Returns the title as a String
  def repo_name
    github_team = GitHubTeam.new(creator.github_client, github_team_id).team
    "#{group_assignment.slug}-#{github_team.slug}"
  end

  # Public: Return the starter_code_repo_id from GroupAssignmentRepos
  # GroupAssignment
  #
  # Returns the starter_code_repo_id as an Integer
  def starter_code_repo_id
    group_assignment.starter_code_repo_id
  end
end
