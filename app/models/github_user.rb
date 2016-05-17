# frozen_string_literal: true
class GitHubUser
  def initialize(client, id)
    @client = client
    @id     = id
  end

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

  # Public
  #
  def login(options = {})
    GitHub::Errors.with_error_handling { @client.user(@id, options).login }
  end

  # Public
  #
  def organization_memberships
    GitHub::Errors.with_error_handling do
      @client.organization_memberships(state: 'active', headers: GitHub::APIHeaders.no_cache_no_store)
    end
  end

  # Public
  #
  def user
    GitHub::Errors.with_error_handling { @client.user(@id) }
  end
end
