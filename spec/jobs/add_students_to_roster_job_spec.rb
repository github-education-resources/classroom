# frozen_string_literal: true

require "rails_helper"

RSpec.describe AddStudentsToRosterJob, type: :job do
  let(:organization) { classroom_org   }
  let(:user)         { classroom_teacher }
  let!(:roster) { create(:roster) }
  let(:channel) { AddStudentsToRosterChannel.channel(roster_id: roster.id, user_id: user.id) }
  let(:identifiers) { %w[John Bob] }
  let(:lms_user_ids) { [1, 2] }

  after do
    roster.roster_entries.destroy_all
  end

  describe "perform" do
    context "add Roster Entries to roster" do
      context "without lms_user_ids" do
        it "adds new identifiers to roster" do
          expect { described_class.perform_now(identifiers, roster, user) }.to change { RosterEntry.count }.by(2)
        end
      end
      context "with lms_user_ids" do
        it "adds lms_user_ids to correct roster entry" do
          described_class.perform_now(identifiers, roster, user, lms_user_ids)
          entry1 = RosterEntry.find_by(identifier: "John")
          entry2 = RosterEntry.find_by(identifier: "Bob")
          expect(entry1.lms_user_id).to eq("1")
          expect(entry2.lms_user_id).to eq("2")
        end
      end
    end

    context "sends ActionCable broadcastss" do
      it "sends update_started message when job starts" do
        expect { described_class.perform_now(identifiers, roster, user) }
          .to have_broadcasted_to(channel)
          .with(status: "update_started")
      end
      it "sends completed  message when job ends" do
        expect { described_class.perform_now(identifiers, roster, user) }
          .to have_broadcasted_to(channel)
          .with(hash_including(status: "completed"))
      end
    end
  end

  describe "#build_message" do
    let(:identifiers) { %w[John Bob] }

    context "when all roster entries are valid" do
      let(:invalid_roster_entries) { [] }

      let(:result) { described_class.new.build_message(invalid_roster_entries, identifiers) }
      it "returns roster update successful message" do
        expect(result).to eq("Roster successfully updated.")
      end
    end

    context "when all roster entries are invalid" do
      let(:invalid_roster_entries) { %w[John Bob] }

      let(:result) { described_class.new.build_message(invalid_roster_entries, identifiers) }
      it "returns roster update failed message" do
        expect(result).to eq("Could not add any students to roster, please try again.")
      end
    end

    context "when some roster entries are invalid" do
      let(:invalid_roster_entries) { %w[Bob] }

      let(:result) { described_class.new.build_message(invalid_roster_entries, identifiers) }
      it "returns partial roster update successful message" do
        expect(result).to eq("Could not add following students: \nBob \n")
      end
    end
  end

  describe "#add_suffix_to_duplicates!" do
    context "when duplicates exist" do
      before do
        RosterEntry.create(identifier: "John", roster: roster)
      end

      let(:result) do
        described_class.new.add_suffix_to_duplicates!(%w[John Bob], roster)
      end

      it "adds suffix to duplicate entries" do
        expect(result.length).to eq(2)
        expect(result[0]).to eq("John-1")
      end
    end
    context "when no duplicates exist" do
      before do
        roster.roster_entries.destroy_all
      end

      let(:result) do
        described_class.new.add_suffix_to_duplicates!(%w[John Bob], roster)
      end

      it "keeps the entries the same" do
        expect(result.length).to eq(2)
        expect(result[0]).to eq("John")
      end
    end
  end
end
