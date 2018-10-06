# frozen_string_literal: true

require "rails_helper"

describe UnlockInviteStatusesService do
  describe "#each_invite_status" do
    before do
      @invite_statuses = InviteStatus.statuses.keys.map { |status| create(:invite_status, status: status) }
    end

    it "yeilds with each invite_status only if the status is locked?" do
      fetched_invite_statuses = []
      described_class.send(:each_invite_status) do |_, invite_status|
        fetched_invite_statuses << invite_status
      end
      expect(fetched_invite_statuses).to eq(@invite_statuses.select(&:locked?))
    end

    it "yeilds with each invite_statuses assocated class" do
      described_class.send(:each_invite_status) do |model, invite_status|
        expect(invite_status.class).to eq(model)
      end
    end
  end

  describe "#create_stat_map" do
    let(:stat_map) { described_class.send(:create_stat_map) }

    UnlockInviteStatusesService::INVITE_STATUS_MODELS.each do |model|
      it "has the field '#{model.to_s.underscore}'" do
        expect(stat_map[model.to_s.underscore]).to be_truthy
      end

      it "has the field 'total_#{model.to_s.underscore.pluralize}'" do
        expect(stat_map["total_#{model.to_s.underscore.pluralize}"]).to be_truthy
      end

      SetupStatus::LOCKED_STATUSES.each do |status|
        it "has the field '#{status}' in '#{model.to_s.underscore}'" do
          expect(stat_map[model.to_s.underscore][status]).to be_truthy
        end
      end
    end
  end

  describe "#unlock_invite_statuses" do
    before do
      described_class::TIME = 0.hours
      @invite_statuses = InviteStatus.statuses.keys.map { |status| create(:invite_status, status: status) }
    end

    it "unlocks all locked? invite_statuses" do
      locked_invite_statuses = @invite_statuses.select(&:locked?)
      described_class.unlock_invite_statuses
      locked_invite_statuses.map(&:reload).each do |invite_status|
        expect(invite_status.unaccepted?).to be_truthy
      end
    end

    it "returns a stat map with totals of all the locked statuses that were unlocked" do
      stat_map = described_class.unlock_invite_statuses
      expect(stat_map)
        .to eq(
          "invite_status" => {
            "waiting" => 1,
            "creating_repo" => 1,
            "importing_starter_code" => 1
          },
          "total_invite_statuses" => 3,
          "group_invite_status" => {
            "waiting" => 0,
            "creating_repo" => 0,
            "importing_starter_code" => 0
          },
          "total_group_invite_statuses" => 0
        )
    end
  end
end
