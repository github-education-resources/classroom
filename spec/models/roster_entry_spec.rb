# frozen_string_literal: true

require "rails_helper"

RSpec.describe RosterEntry, type: :model do
  subject { create(:roster_entry) }

  describe "associations" do
    it "must have a roster" do
      subject.roster = nil
      subject.save

      expect(subject.errors[:roster]).to_not be_nil
    end

    it "can have a user" do
      subject.user = create(:user)

      expect(subject.save).to be_truthy
    end

    it "can have no user" do
      subject.user = nil

      expect(subject.save).to be_truthy
    end
  end

  describe "order_for_view" do
    let(:organization) { classroom_org                                   }
    let(:assignment)   { create(:assignment, organization: organization) }

    let(:roster)   { create(:roster) }

    let(:student1) { create(:user) }
    let(:student2) { create(:user) }

    let!(:assignment_repo) { create(:assignment_repo, assignment: assignment, user: student1) }

    let(:linked_accepted_entry)     { create(:roster_entry, roster: roster, user: student1) }
    let(:not_linked_entry)          { create(:roster_entry, roster: roster)                 }
    let(:linked_not_accepted_entry) { create(:roster_entry, roster: roster, user: student2) }

    it "orders correctly" do
      roster.roster_entries.first.destroy # Ignore the default entry here
      expected_ordering = [linked_accepted_entry, linked_not_accepted_entry, not_linked_entry]

      expect(RosterEntry.where(roster: roster).order_for_view(assignment).to_a).to eq(expected_ordering)
    end

    it "orders correctly, even with no accepted students" do
      roster.roster_entries.first.destroy # Ignore the default entry here
      assignment_repo.delete
      linked_accepted_entry.destroy

      expected_ordering = [linked_not_accepted_entry, not_linked_entry]

      expect(RosterEntry.where(roster: roster).order_for_view(assignment).to_a).to eq(expected_ordering)
    end
  end
end
