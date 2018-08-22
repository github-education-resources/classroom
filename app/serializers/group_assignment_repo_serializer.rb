# frozen_string_literal: true

class GroupAssignmentRepoSerializer < ActiveModel::Serializer
  attributes :id
  attributes :username
  attributes :displayName

  def username
    object.group.title
  end

  # rubocop:disable MethodName
  def displayName
    ""
  end
  # rubocop:enable MethodName
end
