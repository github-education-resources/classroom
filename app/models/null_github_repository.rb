# frozen_string_literal: true

class NullGitHubRepository < NullGitHubResource
  def name
    "Deleted repository"
  end

  def full_name
    "Deleted repository"
  end

  def html_url
    "#"
  end
end
