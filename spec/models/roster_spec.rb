# frozen_string_literal: true

require "rails_helper"

RSpec.describe Roster, type: :model do
  subject { create(:roster) }

  describe "associations" do
    it "can have roster_entries" do
      subject.roster_entries << create(:roster_entry)

      expect(subject.valid?).to be_truthy
    end

    it "can have organizations" do
      subject.organizations << create(:organization)

      expect(subject.valid?).to be_truthy
    end
  end

  describe "#unlinked_entries" do
    it "returns unlinked entries" do
      unlinked_entry = create(:roster_entry)
      linked_entry = create(:roster_entry, user: create(:user))

      subject.roster_entries << unlinked_entry << linked_entry

      expect(subject.unlinked_entries).to include(unlinked_entry)
      expect(subject.unlinked_entries).to_not include(linked_entry)
    end
  end
end
