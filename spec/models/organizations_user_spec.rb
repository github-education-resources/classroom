# frozen_string_literal: true
require 'rails_helper'

RSpec.describe OrganizationsUser, type: :model do
  subject do
    create(:organization)
    OrganizationsUser.first
  end

  describe 'organization' do
    it 'responds to #organization' do
      expect(subject.respond_to?(:organization)).to be_truthy
    end

    it 'has an organization' do
      expect(subject.organization).to be_kind_of(Organization)
    end
  end

  describe 'user' do
    it 'responds to #user' do
      expect(subject.respond_to?(:user)).to be_truthy
    end

    it 'has a user' do
      expect(subject.user).to be_kind_of(User)
    end
  end
end
