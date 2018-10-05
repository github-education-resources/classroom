# frozen_string_literal: true

require 'rails_helper'

shared_examples_for 'setup_status' do
  let(:model) { create(described_class.to_s.underscore) }

  it "has a default status of unaccepted" do
    expect(model.unaccepted?).to be_truthy
  end

  describe "#errored?" do
    it "is errored? when errored_creating_repo?" do
      model.errored_creating_repo!
      expect(model.errored?).to be_truthy
    end

    it "is errored? when errored_importing_starter_code?" do
      model.errored_importing_starter_code!
      expect(model.errored?).to be_truthy
    end
  end

  describe "#setting_up?" do
    it "is setting_up? when accepted?" do
      model.accepted!
      expect(model.setting_up?).to be_truthy
    end

    it "is setting_up? when waiting?" do
      model.waiting!
      expect(model.setting_up?).to be_truthy
    end

    it "is setting_up? when creating_repo?" do
      model.creating_repo!
      expect(model.setting_up?).to be_truthy
    end

    it "is setting_up? when errored_importing_starter_code?" do
      model.importing_starter_code!
      expect(model.setting_up?).to be_truthy
    end
  end

  describe "#unlock_if_locked!" do
    SetupStatus::LOCKED_STATUSES.each do |locked_status|
      context "locked status: #{locked_status}" do
        before do
          model.update(status: locked_status)
        end

        context "when updated over 0 hours ago" do
          it "returns true" do
            expect(model.unlock_if_locked!).to eq(true)
          end

          it "updates the status to unaccepted" do
            model.unlock_if_locked!
            expect(model.unaccepted?).to be_truthy
          end
        end

        context "when updated over 1 hours ago" do
          let(:time) { 1.hour }

          it "returns true" do
            expect(model.unlock_if_locked!(time)).to eq(true)
          end

          it "updates the status to unaccepted" do
            model.unlock_if_locked!(time)
            expect(model.unaccepted?).to be_truthy
          end
        end
      end
    end

    (InviteStatus.statuses.keys - SetupStatus::LOCKED_STATUSES).each do |unlocked_status|
      context "unlocked status: #{unlocked_status}" do
        before do
          model.update(status: unlocked_status)
        end

        it "returns false" do
          expect(model.unlock_if_locked!).to eq(false)
        end
      end
    end
  end
end
