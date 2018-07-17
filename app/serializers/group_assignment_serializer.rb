# frozen_string_literal: true

class GroupAssignmentSerializer < ActiveModel::Serializer
  attributes :id
  attributes :title
  attributes :type
  attributes :organizationGithubId

  def type
    :group
  end

  # rubocop:disable MethodName
  def organizationGithubId
    object.organization.github_id
  end
  # rubocop:enable MethodName
end
