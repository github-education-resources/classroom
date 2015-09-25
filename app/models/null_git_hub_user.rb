class NullGitHubUser < NullGitHubResource
  def html_url
    '#'
  end

  def login
    'ghost'
  end
end
