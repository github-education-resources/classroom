# frozen_string_literal: true

require "rails_helper"

RSpec.describe GroupAssignment, type: :model do
  it_behaves_like "a default scope where deleted_at is not present"

  describe "invitations_enabled default" do
    it "sets invitations_enabled to true by default" do
      options = {
        organization: create(:organization),
        slug: "assignment-1"
      }

      assignment = create(:group_assignment, { title: "foo" }.merge(options))

      expect(assignment.invitations_enabled).to be_truthy
    end
  end

  describe "slug uniqueness" do
    it "verifes that the slug is unique even if the titles are unique" do
      options = {
        organization: create(:organization),
        slug: "group-assignment-1"
      }

      create(:group_assignment, { title: "group-assignment-1" }.merge(options))
      new_group_assignment = build(:group_assignment, { title: "group assignment 1" }.merge(options))

      expect { new_group_assignment.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "title blacklist" do
    it "disallows blacklisted names" do
      groupassignment1 = build(:group_assignment, organization: create(:organization), title: "new")
      groupassignment2 = build(:group_assignment, organization: create(:organization), title: "edit")

      expect { groupassignment1.save! }.to raise_error(ActiveRecord::RecordInvalid)
      expect { groupassignment2.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "uniqueness of title across organization" do
    it "validates that an Assignment in the same organization does not have the same slug" do
      options = {
        title: "Ruby project",
        organization: create(:organization)
      }

      create(:assignment, options)
      group_assignment = build(:group_assignment, options)

      validation_message = "Validation failed: Your assignment repository prefix must be unique"
      expect { group_assignment.save! }.to raise_error(ActiveRecord::RecordInvalid, validation_message)
    end
  end

  describe "uniqueness of title across application" do
    it "allows two organizations to have the same GroupAssignment title and slug" do
      groupassignment1 = create(:assignment, organization: create(:organization))
      groupassignment2 = create(:group_assignment, organization: create(:organization), title: groupassignment1.title)

      expect(groupassignment2.title).to eql(groupassignment1.title)
      expect(groupassignment2.slug).to eql(groupassignment1.slug)
    end
  end

  context "with group_assignment" do
    subject { create(:group_assignment) }

    describe "#flipper_id" do
      it "should return an id" do
        expect(subject.flipper_id).to eq("GroupAssignment:#{subject.id}")
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
