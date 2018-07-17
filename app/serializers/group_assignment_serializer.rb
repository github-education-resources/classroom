class GroupAssignmentSerializer < ActiveModel::Serializer
  attributes :id
  attributes :title
  attributes :type
  attributes :organization_github_id

  def type
    :group
  end

  def organization_github_id
    object.organization.github_id
  end
end
