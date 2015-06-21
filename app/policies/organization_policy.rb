class OrganizationPolicy
  attr_reader :user, :organization

  def initialize(user, organization)
    fail Pundit::NotAuthorizedError, 'must be logged in' unless user
    @user         = user
    @organization = organization
  end

  def index?
    false
  end

  def new?
    create?
  end

  # Creation of objects that need an organization
  def create?
    github_organization_admin?
  end

  def show?
    github_organization_admin?
  end

  def edit?
    update?
  end

  def update?
    github_organization_admin?
  end

  def destroy?
    update?
  end

  def new_assignment?
    github_organization_admin?
  end

  private

  def github_organization_admin?
    @user.github_client.organization_admin?(@organization.github_id)
  end
end
