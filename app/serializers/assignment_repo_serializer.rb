# frozen_string_literal: true

class AssignmentRepoSerializer < ActiveModel::Serializer
  attributes :id
  attributes :username
  attributes :displayName

  def username
    object.user.github_user.login
  end

  # rubocop:disable MethodName
  def displayName
    object.user.github_user.name || ""
  end
  # rubocop:enable MethodName
end
