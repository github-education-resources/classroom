class Organization < ActiveRecord::Base
  has_many :assignments,       dependent: :destroy
  has_many :groupings,         dependent: :destroy
  has_many :group_assignments, dependent: :destroy
  has_many :repo_accesses,     dependent: :destroy

  has_and_belongs_to_many :users

  validates :github_id, :title, presence: true, uniqueness: true

  after_save :validate_minimum_number_of_users

  # Public
  #
  def active_users
    users.where(status: 'active')
  end

  # Public
  #
  def all_assignments
    assignments + group_assignments
  end

  # Public
  #
  def avatar_url(size = 80)
    "https://avatars.githubusercontent.com/u/#{github_id}?size=#{size}"
  end

  # Public
  #
  def fetch_owner
    users.sample
  end

  # Internal
  #
  def validate_minimum_number_of_users
    return if users.count > 0
    error_message = 'must have at least one user'
    errors.add(:users, error_message)
    fail ActiveRecord::RecordInvalid.new(self), error_message
  end
end
