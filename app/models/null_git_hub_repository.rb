class NullGitHubRepository < NullGitHubResource
  def full_name
    'Deleted repository'
  end

  def html_url
    '#'
  end
end
