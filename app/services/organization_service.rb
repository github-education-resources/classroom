class OrganizationService
  def initialize(user)
    @user = user
  end

  # rubocop:disable AbcSize
  def github_organizations
    github_user = GitHubUser.new(@user.github_client, @user.uid)

    @users_github_organizations ||= github_user.organization_memberships.map do |membership|
      {
        classroom: Organization.unscoped.includes(:users).find_by(github_id: membership.organization.id),
        github_id: membership.organization.id,
        login:     membership.organization.login,
        role:      membership.role
      }
    end
  end
  # rubocop:enable AbcSize

  # Check if the current user has any organizations with admin privilege, if so add the user to the corresponding
  # classroom automatically.
  def add_user_to_organizations
    github_organizations.each do |organization|
      classroom = organization[:classroom]
      if classroom.present? && !classroom.users.include?(@user)
        grant_organization_access(classroom)
      end
    end
  end

  private

  def decorated_user
    @decorated_user ||= @user.decorate
  end

  def grant_organization_access(organization)
    github_org = GitHubOrganization.new(@user.github_client, organization.github_id)
    return unless github_org.admin?(decorated_user.login)
    organization.users << @user
  end
end
