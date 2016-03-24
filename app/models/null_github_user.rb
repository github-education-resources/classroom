class NullGitHubUser < NullGitHubResource
  def html_url
    '#'
  end

  def login
    'ghost'
  end

  def name
    'Deleted user'
  end
end
