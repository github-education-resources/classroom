# frozen_string_literal: true
class GitHubUser
  def initialize(client, id)
    @client = client
    @id     = id
  end

  def authorized_access_token?
    GitHub::Errors.with_error_handling do
      Classroom.github_client.check_application_authorization(
        @client.access_token,
        headers: GitHub::APIHeaders.no_cache_no_store
      ).present?
    end
  rescue GitHub::NotFound
    false
  end

  def login(options = {})
    GitHub::Errors.with_error_handling { @client.user(@id, options).login }
  end

  def name(options = {})
    GitHub::Errors.with_error_handling { @client.user(@id, options).name }
  end

  def organization_memberships
    GitHub::Errors.with_error_handling do
      @client.organization_memberships(state: 'active', headers: GitHub::APIHeaders.no_cache_no_store)
    end
  end

  def user
    GitHub::Errors.with_error_handling { @client.user(@id) }
  end
end
