class AssignmentRepo < ActiveRecord::Base
  include GitHubPlan
  include GitHubRepoable

  has_one :organization, -> { unscope(where: :deleted_at) }, through: :assignment

  belongs_to :assignment
  belongs_to :repo_access

  validates :assignment, presence: true

  validates :github_repo_id, presence:   true
  validates :github_repo_id, uniqueness: true

  validates :repo_access, presence:   true
  validates :repo_access, uniqueness: { scope: :assignment }

  # Public: Get the parent assignments creator
  # Returns the User that created the Assignment
  def creator
    assignment.creator
  end

  # Public: Determine if the AssignmentRepo's Assignment is private
  #
  # Example
  #
  #  assignment_repo.private?
  #  # => true
  #
  # Returns a boolean
  def private?
    !assignment.public_repo?
  end

  # Public: Return the GitHub team id from AssignmentRepos RepoAccess
  # Returns the GitHub Team id as an Integer
  def github_team_id
    repo_access.github_team_id
  end

  # Public: Build the title for the AssignmentRepo
  # Returns the title as a String
  def repo_name
    github_user = GitHubUser.new(repo_access.user.github_client)
    "#{assignment.slug}-#{github_user.login}"
  end

  # Public: Return the starter_code_repo_id from AssignmentRepos Assignment
  # Returns the starter_code_repo_id as an Integer
  def starter_code_repo_id
    assignment.starter_code_repo_id
  end
end
