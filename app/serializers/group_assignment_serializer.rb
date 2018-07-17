class GroupAssignmentSerializer < ActiveModel::Serializer
  attributes :title
  attributes :type

  def type
    :group
  end
end