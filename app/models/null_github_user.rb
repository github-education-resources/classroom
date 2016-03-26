class NullGitHubUser < NullGitHubResource

  # internal
  def null_github_user_attributes
    # Courtesy of https://api.github.com/users/ghost
    {
      'login':      'ghost',
      'avatar_url': 'https://avatars.githubusercontent.com/u/10137?v=3',
      'html_url':   'https://github.com/ghost',
      'name':       'Deleted user'
    }
  end
end
