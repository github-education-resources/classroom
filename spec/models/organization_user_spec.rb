# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrganizationUser, type: :model do
  let(:organization) { create(:organization)    }
  let(:user)         { organization.users.first }

  subject { OrganizationUser.find_by(organization: organization, user: user) }

  it "requires an organization" do
    subject.organization = nil
    expect(subject.valid?).to be_falsey
  end

  it "requires a user" do
    subject.user = nil
    expect(subject.valid?).to be_falsey
  end
end
