# frozen_string_literal: true

class GitHubUser < GitHubResource
  # Public: Accept a Repository Invitation on GitHub.
  #
  # Returns True or False.
  def accept_repository_invitation(invitation_id, **options)
    GitHub::Errors.with_error_handling do
      options[:accept] = Octokit::Preview::PREVIEW_TYPES[:repository_invitations]
      @client.accept_repository_invitation(invitation_id, options)
    end
  end

  def authorized_access_token?
    GitHub::Errors.with_error_handling do
      GitHubClassroom.github_client.check_application_authorization(
        @client.access_token,
        headers: GitHub::APIHeaders.no_cache_no_store
      ).present?
    end
  rescue GitHub::Error
    false
  end

  def github_avatar_url(size = 40)
    "#{avatar_url}&size=#{size}"
  end

  def organization_memberships
    GitHub::Errors.with_error_handling do
      @client.organization_memberships(state: "active", headers: GitHub::APIHeaders.no_cache_no_store)
    end
  end

  private

  def github_attributes
    %w[login avatar_url html_url name]
  end
end
