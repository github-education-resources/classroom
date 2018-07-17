class AssignmentSerializer < ActiveModel::Serializer
  attributes :title
  attributes :type

  def type
    :individual
  end
end