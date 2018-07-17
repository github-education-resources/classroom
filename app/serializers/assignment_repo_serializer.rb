# frozen_string_literal: true

class AssignmentRepoSerializer < ActiveModel::Serializer
  attributes :id
  attributes :username
  attributes :repoUrl
  attributes :displayName

  def username
    object.user.github_user.login
  end

  # rubocop:disable MethodName
  def repoUrl
    object.github_repository.html_url
  end

  def displayName
    object.user.github_user.name || ""
  end
  # rubocop:enable MethodName
end
