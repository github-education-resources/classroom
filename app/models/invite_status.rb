# frozen_string_literal: true

class InviteStatus < ApplicationRecord
  belongs_to :assignment_invitation
  belongs_to :user

  enum status: %i[
    unaccepted
    accepted
    waiting
    creating_repo
    importing_starter_code
    completed
    errored_creating_repo
    errored_importing_starter_code
  ]
end
