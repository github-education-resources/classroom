# frozen_string_literal: true

class OrganizationWebhook < ApplicationRecord
  has_many :organizations

  validates :github_id, uniqueness: true, allow_nil: true

  validates :github_organization_id, presence:   true
  validates :github_organization_id, uniqueness: true

  def github_organization
    @github_organization ||= organizations&.first&.github_organization
  end
end
