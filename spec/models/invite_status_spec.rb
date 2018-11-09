# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("spec", "models", "concerns", "setup_status_spec.rb")

RSpec.describe InviteStatus, type: :model do
  let(:invitation)    { create(:assignment_invitation) }
  let(:user)          { create(:user) }

  it { should belong_to(:assignment_invitation) }
  it { should belong_to(:user) }

  it { should validate_presence_of(:assignment_invitation) }
  it { should validate_presence_of(:user) }

  it_behaves_like "setup_status"

  context "when the set of user_id and assignment_invitation_id is not unique" do
    it "is invalid" do
      create(:invite_status, user_id: user.id, assignment_invitation_id: invitation.id)
      invite_status = described_class.new(user_id: user.id, assignment_invitation_id: invitation.id)
      expect { invite_status.save! }
        .to raise_error(ActiveRecord::RecordInvalid, "Validation failed: User should only have 1 invitation per user")
    end
  end
end
