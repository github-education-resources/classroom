# frozen_string_literal: true

class InviteStatus < ApplicationRecord
  belongs_to :assignment_invitation
  belongs_to :user

  validates :user_id, uniqueness: {
    scope: :assignment_invitation_id,
    message: "should only have 1 invitation per user"
  }

  validates :assignment_invitation, presence: true
  validates :user, presence: true

  enum status: {
    unaccepted:                     0,
    accepted:                       1,
    waiting:                        2,
    creating_repo:                  3,
    importing_starter_code:         4,
    completed:                      5,
    errored_creating_repo:          6,
    errored_importing_starter_code: 7
  }

  def errored?
    errored_creating_repo? || errored_importing_starter_code?
  end
end
