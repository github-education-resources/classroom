# frozen_string_literal: true
require 'rails_helper'

RSpec.describe StudentIdentifier, type: :model do
  subject { create(:student_identifier) }

  it_behaves_like 'a default scope where deleted_at is not present'

  context 'relations' do
    context '#type' do
      it 'must have a type' do
        subject.type = nil
        expect(subject.valid?).to be_falsey
        expect(subject.errors).to include(:type)
      end
    end

    context '#organization' do
      it 'must belong to an organization' do
        subject.organization = nil
        expect(subject.valid?).to be_falsey
        expect(subject.errors).to include(:organization)
      end
    end

    context '#user' do
      it 'must belong to a user' do
        subject.user = nil
        expect(subject.valid?).to be_falsey
        expect(subject.errors).to include(:user)
      end
    end
  end

  context 'validations' do
    describe 'uniqueness' do
      it 'verifies uniqueness of organization, user, type' do
        new_student_identifier = subject.dup
        new_student_identifier.update_attributes(user: create(:user))

        expect(new_student_identifier.valid?).to be_falsey
      end

      context 'value' do
        it 'cannot have identical values for the same org and type' do
          new_student_identifier      = subject.dup
          new_student_identifier.user = create(:user)

          expect { new_student_identifier.save! }.to raise_error(ActiveRecord::RecordInvalid)
        end

        it 'allows two identical values for different orgs' do
          type = create(:student_identifier_type)

          new_student_identifier = subject.dup
          new_student_identifier.update_attributes(organization: type.organization, type: type)

          expect(new_student_identifier).to be_valid
        end
      end
    end
  end
end
