class NullGitHubOrganization < NullGitHubResource
  private

  def null_github_attributes
    {
      login:      'ghost',
      avatar_url: 'https://avatars.githubusercontent.com/u/10137?v=3',
      html_url:   'https://github.com/ghost',
      name:       'Deleted organization'
    }
  end
end
