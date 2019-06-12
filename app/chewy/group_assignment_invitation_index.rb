# frozen_string_literal: true

class GroupAssignmentInvitationIndex < Chewy::Index
  define_type GroupAssignmentInvitation.includes(:group_assignment) do
    field :id
    field :key
    field :created_at
    field :updated_at

    field :group_assignment_title,
      value: ->(group_assignment_invitation) { group_assignment_invitation&.group_assignment&.title }
  end
end
