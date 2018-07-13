class GroupAssignmentRepoSerializer < ActiveModel::Serializer
  attributes :id
  attributes :username
  attributes :repoUrl
  attributes :displayName

  def username
    return object.group.title
  end

  def repoUrl
    return object.github_repository.html_url
  end

  def displayName
    return object.group.repo_accesses.map(&:user).map(&:github_user).map(&:login).join(", ")
  end
end