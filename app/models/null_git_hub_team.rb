class NullGitHubTeam < NullGitHubResource
  def name
    'ghost'
  end

  def organization
    NullGitHubOrganization.new
  end

  def slug
    'ghost'
  end
end
