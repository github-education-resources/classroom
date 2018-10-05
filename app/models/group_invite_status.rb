# frozen_string_literal: true

class GroupInviteStatus < ApplicationRecord
  include SetupStatus

  belongs_to :group
  belongs_to :group_assignment_invitation

  validates :group_id, uniqueness: {
    scope: :group_assignment_invitation_id,
    message: "should only have 1 invitation per group"
  }

  validates :group, presence: true
  validates :group_assignment_invitation, presence: true
end
