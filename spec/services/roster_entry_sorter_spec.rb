# frozen_string_literal: true

require "rails_helper"

describe RosterEntrySorter do
  let(:organization) { classroom_org                                   }
  let(:assignment)   { create(:assignment, organization: organization) }

  let(:roster)   { create(:roster) }

  let(:student1) { create(:user) }
  let(:student2) { create(:user) }

  let!(:assignment_repo) { create(:assignment_repo, assignment: assignment, user: student1) }

  let(:linked_accepted_entry)     { create(:roster_entry, roster: roster, user: student1) }
  let(:linked_not_accepted_entry) { create(:roster_entry, roster: roster, user: student2) }
  let(:not_linked_entry)          { create(:roster_entry, roster: roster)                 }

  describe "#sort" do
    it "sorts correctly" do
      unsorted_entries = [not_linked_entry, linked_not_accepted_entry, linked_accepted_entry]
      sorted_entries   = RosterEntrySorter.new(unsorted_entries, assignment).sort

      expect(sorted_entries).to eq([linked_accepted_entry, linked_not_accepted_entry, not_linked_entry])
    end
  end
end
