class GitHubUser < GitHubResource
  def authorized_access_token?
    GitHub::Errors.with_error_handling do
      Classroom.github_client.check_application_authorization(@client.access_token,
                                                              headers: GitHub::APIHeaders.no_cache_no_store
                                                             ).present?
    end
  rescue GitHub::NotFound
    false
  end

  def client_scopes
    GitHub::Errors.with_error_handling do
      @client.scopes(@client.access_token, headers: GitHub::APIHeaders.no_cache_no_store)
    end
  rescue GitHub::Forbidden
    []
  end

  def organization_memberships
    GitHub::Errors.with_error_handling do
      @client.organization_memberships(state: 'active', headers: GitHub::APIHeaders.no_cache_no_store)
    end
  end

  private

  def github_attributes
    %i(login avatar_url html_url name)
  end
end
