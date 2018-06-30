class AssignmentRepoSerializer < ActiveModel::Serializer
  attributes :id
  attributes :username
  attributes :repoUrl
  attributes :displayName

  def username
    return object.user.github_user.login
  end

  def repoUrl
    return object.github_repository.html_url
  end

  def displayName
    return object.user.github_user.name || ""
  end
end