# frozen_string_literal: true

require "rails_helper"

RSpec.describe GroupInviteStatus, type: :invite_status do
  subject { GroupInviteStatus }
  let(:organization) { classroom_org }
  let(:grouping)     { create(:grouping, organization: organization) }
  let(:group)        { Group.create(grouping: grouping, title: "#{Faker::Company.name} Team") }
  let(:invitation)   { create(:group_assignment_invitation) }

  describe "valid", :vcr do
    let(:invite_status) do
      subject.create(group: group, group_assignment_invitation: invitation)
    end

    # TODO: make Group factory so we can make GroupInviteStatus factory to test SetupStatus behavior with:
    # it_behaves_like 'setup_status'

    it "has a default status of unaccepted" do
      expect(invite_status.unaccepted?).to be_truthy
    end

    describe "errored?" do
      it "is errored? when errored_creating_repo?" do
        invite_status.errored_creating_repo!
        expect(invite_status.errored?).to be_truthy
      end

      it "is errored? when errored_importing_starter_code?" do
        invite_status.errored_importing_starter_code!
        expect(invite_status.errored?).to be_truthy
      end
    end

    describe "setting_up?" do
      it "is setting_up? when accepted?" do
        invite_status.accepted!
        expect(invite_status.setting_up?).to be_truthy
      end

      it "is setting_up? when waiting?" do
        invite_status.waiting!
        expect(invite_status.setting_up?).to be_truthy
      end

      it "is setting_up? when creating_repo?" do
        invite_status.creating_repo!
        expect(invite_status.setting_up?).to be_truthy
      end

      it "is setting_up? when errored_importing_starter_code?" do
        invite_status.importing_starter_code!
        expect(invite_status.setting_up?).to be_truthy
      end
    end

    describe "#unlock_if_locked!" do
      SetupStatus::LOCKED_STATUSES.each do |locked_status|
        context "locked status: #{locked_status}" do
          before do
            invite_status.update(status: locked_status)
          end

          context "when updated over 0 hours ago" do
            it "returns true" do
              expect(invite_status.unlock_if_locked!).to eq(true)
            end

            it "updates the status to unaccepted" do
              invite_status.unlock_if_locked!
              expect(invite_status.unaccepted?).to be_truthy
            end
          end

          context "when updated over 1 hours ago" do
            let(:time) { 1.hour }

            it "returns false" do
              expect(invite_status.unlock_if_locked!(elapsed_locked_time: time)).to eq(false)
            end
          end
        end
      end

      (InviteStatus.statuses.keys - SetupStatus::LOCKED_STATUSES).each do |unlocked_status|
        context "unlocked status: #{unlocked_status}" do
          before do
            invite_status.update(status: unlocked_status)
          end

          it "returns false" do
            expect(invite_status.unlock_if_locked!).to eq(false)
          end
        end
      end
    end

    describe "relationships" do
      it "has a group" do
        expect(invite_status.group).to eq(group)
      end

      it "has a group_assignment_invitation" do
        expect(invite_status.group_assignment_invitation).to eq(invitation)
      end
    end
  end

  describe "invalid", :vcr do
    it "without group_id" do
      invite_status = subject.new(group_assignment_invitation_id: invitation.id)
      expect(invite_status.valid?).to be_falsey
    end

    it "without group_assignment_invitation_id" do
      invite_status = subject.new(group_id: group.id)
      expect(invite_status.valid?).to be_falsey
    end

    it "when the set of group_id and group_assignment_invitation_id is not unique" do
      subject.create(group_id: group.id, group_assignment_invitation_id: invitation.id)
      invite_status = subject.new(group_id: group.id, group_assignment_invitation_id: invitation.id)
      expect { invite_status.save! }
        .to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Group should only have 1 invitation per group")
    end
  end
end
