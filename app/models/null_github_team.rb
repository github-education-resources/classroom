class NullGitHubTeam < NullGitHubResource
  def name
    'Deleted team'
  end

  def slug
    'ghost'
  end
end
