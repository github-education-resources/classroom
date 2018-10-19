# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("spec", "models", "concerns", "setup_status_spec.rb")

RSpec.describe InviteStatus, type: :model do
  let(:invitation)    { create(:assignment_invitation) }
  let(:user)          { create(:user) }

  after do
    described_class.destroy_all
  end

  it_behaves_like "setup_status"

  describe "valid" do
    let(:invite_status) { create(:invite_status, user_id: user.id, assignment_invitation_id: invitation.id) }

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
      invite_status = described_class.new(assignment_invitation_id: invitation.id)
      expect(invite_status.valid?).to be_falsey
    end

    it "without assignment_invitation_id" do
      invite_status = described_class.new(user_id: user.id)
      expect(invite_status.valid?).to be_falsey
    end

    it "when the set of user_id and assignment_invitation_id is not unique" do
      create(:invite_status, user_id: user.id, assignment_invitation_id: invitation.id)
      invite_status = described_class.new(user_id: user.id, assignment_invitation_id: invitation.id)
      expect { invite_status.save! }
        .to raise_error(ActiveRecord::RecordInvalid, "Validation failed: User should only have 1 invitation per user")
    end
  end
end
