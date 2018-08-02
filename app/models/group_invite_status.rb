# frozen_string_literal: true

class GroupInviteStatus < ApplicationRecord
  belongs_to :group
  belongs_to :group_assignment_invitation
end
