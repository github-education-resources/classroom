# frozen_string_literal: true

class OrganizationWebhook < ApplicationRecord
  has_many :organizations

  validates :github_id, uniqueness: true

  validates :github_organization_id, presence:   true
  validates :github_organization_id, uniqueness: true

  def github_organization
    @github_organization ||= GitHubOrganization.new(organizations.first.github_client, github_organization_id)
  end
end
