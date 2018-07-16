# frozen_string_literal: true

require "rails_helper"

RSpec.describe Assignment, type: :model do
  it_behaves_like "a default scope where deleted_at is not present"

  describe "invitations_enabled default" do
    it "sets invitations_enabled to true by default" do
      options = {
        organization: create(:organization),
        slug: "assignment-1"
      }

      assignment = create(:assignment, { title: "foo" }.merge(options))

      expect(assignment.invitations_enabled).to be_truthy
    end
  end

  describe "slug uniqueness" do
    it "verifes that the slug is unique even if the titles are unique" do
      options = {
        organization: create(:organization),
        slug: "assignment-1"
      }

      create(:assignment, { title: "foo" }.merge(options))
      new_assignment = build(:assignment, { title: "bar" }.merge(options))

      expect { new_assignment.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "title blacklist" do
    it "disallows blacklisted names" do
      assignment1 = build(:assignment, organization: create(:organization), title: "new")
      assignment2 = build(:assignment, organization: create(:organization), title: "edit")

      expect { assignment1.save! }.to raise_error(ActiveRecord::RecordInvalid)
      expect { assignment2.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "uniqueness of title across organization" do
    it "validates that a GroupAssignment in the same organization does not have the same slug" do
      options = {
        title: "Ruby project",
        organization: create(:organization)
      }

      create(:group_assignment, options)
      validation_message = "Validation failed: Your assignment repository prefix must be unique"

      expect { create(:assignment, options) }.to raise_error(ActiveRecord::RecordInvalid, validation_message)
    end
  end

  describe "uniqueness of title across application" do
    it "allows two organizations to have the same Assignment title and slug" do
      assignment1 = create(:assignment, organization: create(:organization))
      assignment2 = create(:assignment, organization: create(:organization), title: assignment1.title)

      expect(assignment2.title).to eql(assignment1.title)
      expect(assignment2.slug).to  eql(assignment1.slug)
    end
  end

  context "with assignment" do
    subject { create(:assignment) }

    describe "#flipper_id" do
      it "should return an id" do
        expect(subject.flipper_id).to eq("Assignment:#{subject.id}")
      end
    end

    describe "#public?" do
      it "returns true if Assignments public_repo column is true" do
        expect(subject.public?).to be(true)
      end
    end

    describe "#private?" do
      it "returns false if Assignments public_repo column is true" do
        expect(subject.private?).to be(false)
      end
    end
  end
end
