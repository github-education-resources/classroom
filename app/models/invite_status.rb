# frozen_string_literal: true

class InviteStatus < ApplicationRecord
  belongs_to :assignment_invitation
  belongs_to :user
end
