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
end
