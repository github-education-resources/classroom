# frozen_string_literal: true

require "rails_helper"

RSpec.describe FormView do
  let(:assignment) { create(:assignment) }

  subject { FormView.new(subject: assignment) }

  describe "#errors_for?" do
    context "when there are errors" do
      before do
        assignment.errors.add(:title, "is all wrong")
      end

      it "returns true" do
        expect(subject.errors_for?(:title)).to be_truthy
      end
    end

    context "when there are no errors" do
      it "returns false" do
        expect(subject.errors_for?(:title)).to be_falsey
      end
    end

    context "when there are errors on other fields, but nothing on field" do
      before do
        assignment.errors.add(:slug, "is all wrong")
      end

      it "returns false" do
        expect(subject.errors_for?(:title)).to be_falsey
      end
    end
  end

  describe "#form_class_for" do
    context "when there are errors" do
      before do
        assignment.errors.add(:title, "is all wrong")
      end

      it 'returns "form errored"' do
        expect(subject.form_class_for(:title)).to eq("form-group errored primer-new")
      end
    end

    context "when there are no errors" do
      it 'returns "form"' do
        expect(subject.form_class_for(:title)).to eq("form-group")
      end
    end
  end

  describe "#error_message_for" do
    context "when there are no errors" do
      it 'returns ""' do
        expect(subject.error_message_for(:title)).to eq("")
      end
    end

    context "when there are errors" do
      before do
        assignment.errors.add(:title, "is all wrong")
      end

      it "returns correct error message" do
        expect(subject.error_message_for(:title)).to eq(assignment.errors.full_messages_for(:title).join(", "))
      end
    end
  end

  describe "#errors_for_object?" do
    before(:each) do
      assignment.errors.clear
    end

    it "returns false when object is nil" do
      expect(subject.errors_for_object?(nil)).to be false
    end

    it "returns false when no errors exist" do
      expect(subject.errors_for_object?(assignment)).to be false
    end

    it "returns true when errors exist" do
      assignment.errors.add(:title, "is all wrong")
      expect(subject.errors_for_object?(assignment)).to be true
    end
  end

  describe "#error_message_for_object" do
    let(:group_assignment) { create(:group_assignment) }

    context "errors exist" do
      before do
        group_assignment.grouping.errors.add(:title, "is already taken.")
      end

      it "returns correct error message" do
        expect(subject.error_message_for_object(group_assignment.grouping))
          .to eql(group_assignment.grouping.errors.full_messages.join(", "))
      end
    end

    context "errors do not exist" do
      it "returns a blank" do
        expect(subject.error_message_for_object(group_assignment.grouping)).to eql("")
      end
    end
  end
end
