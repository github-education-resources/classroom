# frozen_string_literal: true
class GitHubUser < GitHubResource
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

  def github_avatar_url(size = 40)
    "#{avatar_url}&size=#{size}"
  end

  def name(options = {})
    GitHub::Errors.with_error_handling { @client.user(@id, options).name }
  end

  def organization_memberships
    GitHub::Errors.with_error_handling do
      @client.organization_memberships(state: 'active', headers: GitHub::APIHeaders.no_cache_no_store)
    end
  end

  private

  def attributes
    %w(login avatar_url html_url name)
  end
end
