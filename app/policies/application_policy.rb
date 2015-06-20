class ApplicationPolicy
  attr_reader :user, :record

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  protected

  def github_organization_admin?(user, organization_github_id)
    user.github_client.organization_admin?(organization_github_id)
  end
end
