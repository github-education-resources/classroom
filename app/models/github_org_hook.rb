# frozen_string_literal: true

class GitHubOrgHook < GitHubOrgResource
  def active?
    active
  end

  private

  def github_attributes
    %w[active name created_at updated_at]
  end
end
