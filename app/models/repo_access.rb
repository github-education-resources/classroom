# frozen_string_literal: true
class RepoAccess < ApplicationRecord
  include GitHubTeamable

  update_index('stafftools#repo_access') { self }

  belongs_to :user
  belongs_to :classroom, -> { unscope(where: :deleted_at) }

  has_many :assignment_repos

  has_and_belongs_to_many :groups

  validates :classroom, presence: true
  validates :classroom, uniqueness: { scope: :user }

  validates :user, presence: true
  validates :user, uniqueness: { scope: :organization }

  before_validation(on: :create) do
    if classroom
      add_membership_to_github_organization
      accept_membership_to_github_organization
    end
  end

  before_destroy :silently_destroy_github_team
  before_destroy :silently_remove_organization_member

  private

  def add_membership_to_github_organization
    classroom.github_organization.add_membership(user.github_user.login)
  end

  def accept_membership_to_github_organization
    github_organization = GitHubOrganization.new(user.github_client, classroom.github_organization_id)
    github_organization.accept_membership(user.github_user.login)
  rescue GitHub::Error
    silently_remove_organization_member
    raise GitHub::Error, 'Failed to add user to the Classroom, please try again'
  end

  def remove_organization_member
    github_organization = GitHubOrganization.new(classroom.github_client, classroom.github_organization_id)
    github_organization.remove_organization_member(user.uid)
  end

  def silently_remove_organization_member
    remove_organization_member
    true # Destroy ActiveRecord object even if we fail to delete the repository
  end

  def title
    user.github_user.login
  end
end
