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

    let(:linked_accepted_entry)     { create(:roster_entry, roster: roster, user: student1, identifier: "a")  }
    let(:not_linked_entry)          { create(:roster_entry, roster: roster, identifier: "b")                  }
    let(:linked_not_accepted_entry) { create(:roster_entry, roster: roster, user: student2, identifier: "c")  }

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

  describe "create_entries" do
    let(:organization) { classroom_org   }
    let(:roster)       { create(:roster) }

    context "all entries valid" do
      let(:result) do
        RosterEntry.create_entries(identifiers: %w[1 2], roster: roster)
      end

      it "creates two roster entries" do
        expect(result.length).to eq(2)

        expect(result[0]).to eq(RosterEntry.find_by(identifier: "1", roster: roster))
        expect(result[1]).to eq(RosterEntry.find_by(identifier: "2", roster: roster))
      end
    end

    context "some entries not valid" do
      before do
        RosterEntry.create(identifier: "1", roster: roster)
      end

      let(:result) do
        RosterEntry.create_entries(identifiers: %w[1 2], roster: roster)
      end

      it "creates one roster entries" do
        expect(result.length).to eq(1)

        expect(result[0]).to eq(RosterEntry.find_by(identifier: "2", roster: roster))
      end
    end

    context "no roster entries valid" do
      before do
        RosterEntry.create(identifier: "1", roster: roster)
        RosterEntry.create(identifier: "2", roster: roster)
      end

      let(:result) do
        RosterEntry.create_entries(identifiers: %w[1 2], roster: roster)
      end

      it "creates no roster entries" do
        expect(result.length).to eq(0)
      end
    end

    context "some other error" do
      before do
        errored_entry = RosterEntry.new(roster: roster)
        errored_entry.errors[:base] << "Something went wrong ¯\\_(ツ)_/¯ "

        allow(RosterEntry).to receive(:create).and_return(errored_entry)
      end

      it "raises RosterEntry::IdentifierCreationError" do
        expect do
          RosterEntry.create_entries(identifiers: %w[1], roster: roster)
        end.to raise_error(RosterEntry::IdentifierCreationError)
      end
    end
  end
end
