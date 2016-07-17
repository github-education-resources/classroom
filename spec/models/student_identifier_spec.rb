# frozen_string_literal: true
require 'rails_helper'

RSpec.describe StudentIdentifier, type: :model do
  it_behaves_like 'a default scope where deleted_at is not present'

  describe 'uniqueness' do
    let(:organization)            { create(:organization)    }
    let(:user)                    { organization.users.first }

    let(:student_identifier_type) { create(:student_identifier_type, organization: organization) }

    it 'verifies uniqueness of organization, user and student identifier type' do
      create(:student_identifier,
             organization: organization,
             user: user,
             student_identifier_type: student_identifier_type,
             value: 'Test')

      new_student_identifier = build(:student_identifier,
                                     organization: organization,
                                     user: user,
                                     student_identifier_type: student_identifier_type,
                                     value: 'Test 2')

      expect { new_student_identifier.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
