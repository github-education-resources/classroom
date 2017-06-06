# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FormFieldWithErrors::EditView do
  let(:assignment) { create(:assignment) }

  subject do
    FormFieldWithErrors::EditView.new(
      object: assignment,
      field: :title
    )
  end

  describe 'attributes' do
    it 'responds to object' do
      expect(subject).to respond_to(:object)
    end

    it 'responds to field' do
      expect(subject).to respond_to(:field)
    end
  end

  describe '#has_errors?' do
    context 'when there are errors' do
      before do
        assignment.errors.add(:title, 'is all wrong')
      end

      it 'returns true' do
        expect(subject.has_errors?).to be_truthy
      end
    end

    context 'when there are no errors' do
      it 'returns false' do
        expect(subject.has_errors?).to be_falsey
      end
    end

    context 'when there are errors on other fields, but nothing on field' do
      before do
        assignment.errors.add(:slug, 'is all wrong')
      end

      it 'returns false' do
        expect(subject.has_errors?).to be_falsey
      end
    end
  end

  describe '#form_class' do
    context 'when there are errors' do
      before do
        assignment.errors.add(:title, 'is all wrong')
      end

      it 'returns "form errored"' do
        expect(subject.form_class).to eq('form errored')
      end
    end

    context 'when there are no errors' do
      it 'returns "form"' do
        expect(subject.form_class).to eq('form')
      end
    end
  end

  describe '#error_message' do
    context 'when there are no errors' do
      it 'returns ""' do
        expect(subject.error_message).to eq('')
      end
    end

    context 'when there are errors' do
      before do
        assignment.errors.add(:title, 'is all wrong')
      end

      it 'returns correct error message' do
        expect(subject.error_message).to eq(assignment.errors.full_messages_for(:title).join(', '))
      end
    end
  end
end
