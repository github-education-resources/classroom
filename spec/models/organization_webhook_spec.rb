# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrganizationWebhook, type: :model do
  let(:organization) { classroom_org }
  subject { create(:organization, github_organization_id: organization.github_id) }


end
