class GitHubUser < GitHubResource
  def accept_membership_to(github_organization:)
    return if github_organization.member?(github_user: self)

    GitHub::Errors.with_error_handling do
      client.update_organization_membership(github_organization.login, state: 'active')
    end
  end

  def active_admin?(github_organization:)
    GitHub::Errors.with_error_handling do
      membership = client.organization_membership(github_organization.login, user: login)
      membership.role == 'admin' && membership.state == 'active'
    end
  end

  def authorized_access_token?
    GitHub::Errors.with_error_handling do
      Classroom.github_client.check_application_authorization(
        access_token,
        headers: GitHub::APIHeaders.no_cache_no_store
      ).present?
    end
  rescue GitHub::NotFound
    false
  end

  def client_scopes
    GitHub::Errors.with_error_handling do
      client.scopes(access_token, headers: GitHub::APIHeaders.no_cache_no_store)
    end
  rescue GitHub::Forbidden
    []
  end

  def disabled?
    return @disabled if defined?(@disabled)
    @disabled = (login == 'ghost')
  end

  def organization_memberships
    GitHub::Errors.with_error_handling do
      client.organization_memberships(state: 'active', headers: GitHub::APIHeaders.no_cache_no_store)
    end
  end

  # Internal
  def github_attributes
    %w(login avatar_url html_url name)
  end
end
