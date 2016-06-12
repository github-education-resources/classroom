# frozen_string_literal: true
class OrganizationsUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :organization
end
