# frozen_string_literal: true

require "rails_helper"

describe UnlockInviteStatusesService do

  describe "#each_invite_status" do
    before do
      @invite_statuses = InviteStatus.statuses.keys.map {|status| create(:invite_status, status: status) }
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
end
