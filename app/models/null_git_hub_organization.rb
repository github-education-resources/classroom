class NullGitHubOrganization < NullGitHubResource
  def html_url
    '#'
  end

  def login
    'ghost'
  end

  def name
    'Deleted organization'
  end
end
