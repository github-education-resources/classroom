# frozen_string_literal: true

require "rails_helper"

RSpec.describe InviteStatus, type: :model do
  subject { InviteStatus }

  let(:invitation)    { create(:assignment_invitation) }
  let(:user)          { create(:user) }

  after do
    subject.destroy_all
  end

  describe "valid" do
    let(:invite_status) { create(:invite_status, user_id: user.id, assignment_invitation_id: invitation.id) }

    it "has a default status of unaccepted" do
      expect(invite_status.unaccepted?).to be_truthy
    end

    it "is errored? when errored_creating_repo?" do
      invite_status.errored_creating_repo!
      expect(invite_status.errored?).to be_truthy
    end

    it "is errored? when errored_importing_starter_code?" do
      invite_status.errored_importing_starter_code!
      expect(invite_status.errored?).to be_truthy
    end

    it "is errored? only when errored_creating_repo? or errored_importing_starter_code?" do
      non_errored_statuses = subject.statuses.keys.reject do |status|
        status == "errored_creating_repo" || status == "errored_importing_starter_code"
      end
      non_errored_statuses.each do |status|
        invite_status.update(status: status)
        expect(invite_status.errored?).to be_falsey
      end
    end

    describe "relationships" do
      it "has a user" do
        expect(invite_status.user).to eq(user)
      end

      it "has a assignment_invitation" do
        expect(invite_status.assignment_invitation).to eq(invitation)
      end
    end
  end

  describe "invalid" do
    it "without user_id" do
      invite_status = subject.new(assignment_invitation_id: invitation.id)
      expect(invite_status.valid?).to be_falsey
    end

    it "without assignment_invitation_id" do
      invite_status = subject.new(user_id: user.id)
      expect(invite_status.valid?).to be_falsey
    end

    it "when the set of user_id and assignment_invitation_id is not unique" do
      create(:invite_status, user_id: user.id, assignment_invitation_id: invitation.id)
      invite_status = subject.new(user_id: user.id, assignment_invitation_id: invitation.id)
      expect { invite_status.save! }
        .to raise_error(ActiveRecord::RecordInvalid, "Validation failed: User should only have 1 invitation per user")
    end
  end
end
