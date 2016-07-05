# frozen_string_literal: true
require 'rails_helper'

RSpec.describe StudentIdentifier, type: :model do
  include ActiveJob::TestHelper

  it_behaves_like 'a default scope where deleted_at is not present'

  describe 'uniqueness' do
    let(:organization)            { create(:organization)    }
    let(:user)                    { organization.users.first }

    let(:student_identifier_type) { create(:student_identifier_type, organization: organization)                     }
    let(:group_assignment)        { create(:group_assignment, organization: organization, user: user, value: 'Test') }

    it 'verifies uniqueness of organization, user and student identifier type' do
      create(:student_identifier,
             organization: organization,
             user: user,
             student_identifier_type: student_identifier_type,
             value: 'Test')

      new_group_assignment = build(:student_identifier,
                                   organization: organization,
                                   user: user,
                                   student_identifier_type: student_identifier_type,
                                   value: 'Test 2')

      expect { new_group_assignment.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
