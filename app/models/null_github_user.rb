class NullGitHubUser < NullGitHubResource
  # Internal
  def null_github_attributes
    {
      login:      'ghost',
      html_url:   'https://github.com/ghost',
      name:       'Deleted user'
    }
  end
end
