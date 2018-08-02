# frozen_string_literal: true

class GroupInviteStatus < ApplicationRecord
  ERRORED_STATUSES = %w[errored_creating_repo errored_importing_starter_code].freeze
  SETUP_STATUSES = %w[accepted waiting creating_repo importing_starter_code].freeze

  belongs_to :group
  belongs_to :group_assignment_invitation

  validates :group_id, uniqueness: {
    scope: :agroup_assignment_invitation_id,
    message: "should only have 1 invitation per group"
  }

  validates :group, presence: true
  validates :group_assignment_invitation, presence: true

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
    ERRORED_STATUSES.include?(status)
  end

  def setting_up?
    SETUP_STATUSES.include?(status)
  end
end
