# frozen_string_literal: true

class GroupAssignmentRepoSerializer < ActiveModel::Serializer
  attributes :id
  attributes :username
  attributes :displayName

  def username
    object.group.github_team.name
  end

  # rubocop:disable MethodName
  def displayName
    ""
  end
  # rubocop:enable MethodName
end
