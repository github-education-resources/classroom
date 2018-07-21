# frozen_string_literal: true

class InviteStatus < ApplicationRecord
  belongs_to :assignment_invitation
  belongs_to :user

  enum status: {
    unaccepted:                     0,
    accepted:                       1,
    waiting:                        2,
    creating_repo:                  3,
    importing_starter_code:         4,
    completed:                      5,
    errored_creating_repo:          6,
    errored_importing_starter_code: 7,
  }
end
