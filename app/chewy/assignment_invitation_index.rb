# frozen_string_literal: true

class AssignmentInvitationIndex < Chewy::Index
  define_type AssignmentInvitation.includes(:assignment) do
    field :id
    field :key
    field :created_at
    field :updated_at

    field :assignment_title, value: ->(assignment_invitation) { assignment_invitation&.assignment&.title }
  end
end
