class AssignmentSerializer < ActiveModel::Serializer
  attributes :id
  attributes :title
  attributes :type
  attributes :organization_github_id

  def type
    :individual
  end

  def organization_github_id
    object.organization.github_id
  end
end