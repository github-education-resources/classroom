class NullGitHubRepository < NullGitHubResource
  # Internal
  def null_github_attributes
    {
      full_name:  'Deleted repository',
      html_url:   '#'
    }
  end
end
