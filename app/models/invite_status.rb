# frozen_string_literal: true

class InviteStatus < ApplicationRecord
  include SetupStatus

  belongs_to :assignment_invitation
  belongs_to :user

  validates :user_id, uniqueness: {
    scope: :assignment_invitation_id,
    message: "should only have 1 invitation per user"
  }

  validates :assignment_invitation, presence: true
  validates :user, presence: true
end
