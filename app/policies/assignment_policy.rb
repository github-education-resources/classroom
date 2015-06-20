class AssignmentPolicy < ApplicationPolicy
  def create?
    github_organization_admin?(@user, @organization.github_id)
  end
end
