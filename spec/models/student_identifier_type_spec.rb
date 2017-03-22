# frozen_string_literal: true
require 'rails_helper'

RSpec.describe StudentIdentifierType, type: :model do
  subject { create(:student_identifier_type) }

  it_behaves_like 'a default scope where deleted_at is not present'

  context 'relations' do
    context '#student_identifiers' do
      it 'has many student identifiers' do
        expect(subject.student_identifiers).to be_kind_of(ActiveRecord::Associations::CollectionProxy)
      end
    end

    context '#organization' do
      it 'must belong to an organization' do
        type = build(:student_identifier_type, organization: nil)

        expect(type.valid?).to be_falsey
        expect(type.errors).to include(:organization)
      end
    end
  end

  context 'validations' do
    context 'uniqueness' do
      it 'has a unique name in scope of the organization' do
        type = build(:student_identifier_type, name: subject.name, organization: subject.organization)
        expect(type.valid?).to be_falsey
      end

      it 'can have the same name for different organizations' do
        type = build(:student_identifier_type, name: subject.name)
        expect(type.valid?).to be_truthy
      end
    end
  end
end
