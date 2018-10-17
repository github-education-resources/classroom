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
