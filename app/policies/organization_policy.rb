class OrganizationPolicy < ApplicationPolicy
  attr_reader :user, :organization

  # Creation of objects that need an organization
  def create?
    github_organization_admin?(@user, @organization.github_id)
  end

  def new_assignment?
    github_organization_admin?(@user, @organization.github_id)
  end

  def show?
    github_organization_admin?(@user, @organization.github_id)
  end

  def update?
    github_organization_admin?(@user, @organization.github_id)
  end

  def destroy?
    github_organization_admin?(@user, @organization.github_id)
  end
end
