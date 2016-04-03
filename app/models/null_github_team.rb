class NullGitHubTeam < NullGitHubResource
  # Internal
  def null_github_attributes
    {
      name: 'Deleted team',
      slug: 'ghost'
    }
  end
end
