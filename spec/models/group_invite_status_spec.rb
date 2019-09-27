# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("spec", "models", "concerns", "setup_status_spec.rb")

RSpec.describe GroupInviteStatus, type: :invite_status do
  subject { GroupInviteStatus }
  let(:organization) { classroom_org }
  let(:grouping)     { create(:grouping, organization: organization) }
  let(:group)        { create(:group, grouping: grouping) }
  let(:invitation)   { create(:group_assignment_invitation) }

  describe "valid" do
    let(:invite_status) { create(:group_invite_status, group: group, group_assignment_invitation: invitation) }

    it_behaves_like "setup_status"

    describe "relationships" do
      it "has a group" do
        expect(invite_status.group).to eq(group)
      end

      it "has a group_assignment_invitation" do
        expect(invite_status.group_assignment_invitation).to eq(invitation)
      end
    end
  end

  describe "invalid" do
    it "without group_id" do
      invite_status = subject.new(group_assignment_invitation_id: invitation.id)
      expect(invite_status.valid?).to be_falsey
    end

    it "without group_assignment_invitation_id" do
      invite_status = subject.new(group_id: group.id)
      expect(invite_status.valid?).to be_falsey
    end

    it "when the set of group_id and group_assignment_invitation_id is not unique" do
      create(:group_invite_status, group: group, group_assignment_invitation: invitation)
      invite_status = subject.new(group_id: group.id, group_assignment_invitation_id: invitation.id)
      expect { invite_status.save! }
        .to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Group should only have 1 invitation per group")
    end
  end
end
