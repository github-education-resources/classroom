# frozen_string_literal: true
require 'rails_helper'

RSpec.describe StudentIdentifier, type: :model do
  subject { create(:student_identifier_type, organization: create(:organization)) }

  it_behaves_like 'a default scope where deleted_at is not present'

  describe 'uniqueness' do
    it 'verifies uniqueness of organization, user and student identifier type' do
      options = {
        organization: subject.organization,
        user: create(:user),
        student_identifier_type: subject
      }

      create(:student_identifier, options.merge(value: 'Test'))
      new_student_identifier = build(:student_identifier, options.merge(value: 'Test 2'))

      expect { new_student_identifier.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
