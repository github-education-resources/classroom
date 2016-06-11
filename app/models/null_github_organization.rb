# frozen_string_literal: true
class NullGitHubOrganization < NullGitHubResource
  def avatar_url
    'https://avatars.githubusercontent.com/u/10137?v=3'
  end

  def html_url
    'https://github.com/ghost'
  end

  def login
    'ghost'
  end

  def name
    'Deleted organization'
  end
end
