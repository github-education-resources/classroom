# frozen_string_literal: true

class OrganizationUser < ApplicationRecord
  self.table_name = "organizations_users"

  update_index("stafftools#organization_user") { self }

  belongs_to :organization
  belongs_to :user

  validates :organization, presence: true
  validates :user,         presence: true
end
