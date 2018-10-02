# frozen_string_literal: true

class NullGitHubOrganization < NullGitHubResource
  def id
    10_137
  end

  def avatar_url
    "https://avatars.githubusercontent.com/u/10137?v=3"
  end

  def html_url
    "https://github.com/ghost"
  end

  def login
    "ghost"
  end

  def name
    "Deleted organization"
  end

  def node_id
    "MDQ6VXNlcjEwMTM3"
  end
end
