# frozen_string_literal: true

class AssignmentSerializer < ActiveModel::Serializer
  attributes :id
  attributes :title
  attributes :type
  attributes :organizationGithubId

  def type
    :individual
  end

  # rubocop:disable MethodName
  def organizationGithubId
    object.organization.github_id
  end
  # rubocop:enable MethodName
end
