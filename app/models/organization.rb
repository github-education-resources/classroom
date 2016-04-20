# frozen_string_literal: true
class Organization < ActiveRecord::Base
  include Flippable
  include Sluggable

  update_index('stafftools#organization') { self }

  default_scope { where(deleted_at: nil) }

  has_many :assignments,       dependent: :destroy
  has_many :groupings,         dependent: :destroy
  has_many :group_assignments, dependent: :destroy
  has_many :repo_accesses,     dependent: :destroy

  has_and_belongs_to_many :users

  validates :github_id, presence: true, uniqueness: true

  validates :title, presence: true, length: { maximum: 60 }

  validates :email_domain,
            length: {
              maximum: 80
            },
            allow_blank: true,
            format: {
              with: /(@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z)/i,
              message: 'is not valid'
            }

  validates :slug, uniqueness: true

  def all_assignments
    assignments + group_assignments
  end

  def github_client
    users.sample.github_client
  end

  def slugify
    self.slug = "#{github_id} #{title}".parameterize
  end
end
