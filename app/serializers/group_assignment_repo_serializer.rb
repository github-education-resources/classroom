class GroupAssignmentRepoSerializer < ActiveModel::Serializer
  attributes :id
  attributes :username
  attributes :repoUrl
  attributes :displayName

  def username
    object.group.title
  end

  def repoUrl
    object.github_repository.html_url
  end

  def displayName
    object.group.repo_accesses.map(&:user).map(&:github_user).map(&:login).join(", ")
  end
end
