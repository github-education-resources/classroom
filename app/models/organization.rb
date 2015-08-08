class Organization < ActiveRecord::Base
  extend FriendlyId
  friendly_id :title, use: [:slugged, :finders]

  default_scope { where(deleted_at: nil) }

  has_many :assignments,       dependent: :destroy
  has_many :groupings,         dependent: :destroy
  has_many :group_assignments, dependent: :destroy
  has_many :repo_accesses,     dependent: :destroy

  has_and_belongs_to_many :users, presence: true, before_remove: [:verify_not_assignment_creator, :verify_not_last_user]

  validates :github_id, presence: true, uniqueness: true
  validates :title,     presence: true, uniqueness: { case_sensitive: false }

  # Public
  #
  def all_assignments
    assignments + group_assignments
  end

  # Public
  #
  def github_client
    users.sample.github_client
  end

  private

  # Internal
  #
  def verify_not_last_user(_user)
    return if users.where(state: 'active').count > 1
    errors.add(:base, 'This organization must have at least one active user')
    fail ActiveRecord::RecordInvalid.new(self), 'unable to remove user'
  end

  # Internal
  #
  def verify_not_assignment_creator(user)
    users_assignments = assignments.where(creator: user) + group_assignments.where(creator: user)

    return unless users_assignments.present?

    errors.add(:user, 'is the creator of one or more assignments, and cannot be removed at this time')
    fail ActiveRecord::RecordInvalid.new(self), 'unable to remove user'
  end
end
