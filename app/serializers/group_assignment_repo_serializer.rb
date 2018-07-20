# frozen_string_literal: true

class GroupAssignmentRepoSerializer < ActiveModel::Serializer
  attributes :id
  attributes :username
  attributes :repoUrl
  attributes :displayName

  def username
    object.group.title
  end

  # rubocop:disable MethodName
  def repoUrl
    object.github_repository.html_url
  end

  def displayName
    ""
  end
  # rubocop:enable MethodName
end
