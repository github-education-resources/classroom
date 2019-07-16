# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssignmentInvitation, type: :model do
  subject { create(:assignment_invitation) }

  let(:invitation)  { subject }
  let(:user)        { classroom_student }

  it_behaves_like "a default scope where deleted_at is not present"

  it "should have a key after initialization" do
    assignment_invitation = build(:assignment_invitation)
    expect(assignment_invitation.key).to_not be_nil
  end

  describe ".search" do
    it "searches by id" do
      results = AssignmentInvitation.search(invitation.id)
      expect(results.to_a).to include(invitation)
    end

    it "searches by key" do
      results = AssignmentInvitation.search(invitation.key)
      expect(results.to_a).to include(invitation)
    end

    it "does not return the assignment when it shouldn't" do
      results = AssignmentInvitation.search("spaghetto")
      expect(results.to_a).to_not include(invitation)
    end
  end

  describe "#status" do
    it "should create an invite status for a user when one does not exist" do
      expect(InviteStatus).to receive(:create).with(user: user, assignment_invitation: invitation)
      invitation.status(user)
    end

    it "should find an invite status for a user when one does exist" do
      expect(invitation.invite_statuses).to receive(:find_by).with(user: user)
      invitation.status(user)
    end

    it "retruns the InviteStatus that belongs to the user and the invite" do
      invite_status = create(:invite_status, user_id: user.id, assignment_invitation_id: invitation.id)
      expect(invitation.status(user)).to eq(invite_status)
    end
  end

  describe "short_key" do
    it "allows multiple invitations with nil short_key" do
      first_inv = create(:assignment_invitation)
      second_inv = create(:assignment_invitation)

      first_inv.update_attributes!(short_key: nil)
      second_inv.short_key = nil

      expect(second_inv.save).to be_truthy
    end
  end

  describe "#redeem_for" do
    let(:student) { create(:user) }

    let(:result) do
      assignment_repo = create(:assignment_repo, user: student)
      AssignmentRepo::Creator::Result.success(assignment_repo)
    end

    it "returns a AssignmentRepo::Creator::Result with the assignment repo" do
      allow(invitation).to receive(:redeem_for).with(student).and_return(result)
      result = invitation.redeem_for(student)

      expect(result.success?).to be_truthy
      expect(result.assignment_repo).to eql(AssignmentRepo.last)
    end

    it "fails if invitations are not enabled" do
      assignment = invitation.assignment

      assignment.invitations_enabled = false
      assignment.save

      result = invitation.redeem_for(student)
      expect(result.success?).to be_falsey
    end
  end

  describe "#title" do
    it "returns the assignments title" do
      expect(invitation.title).to eql(invitation.assignment.title)
    end
  end

  describe "#to_param" do
    it "should return the key" do
      expect(invitation.to_param).to eql(invitation.key)
    end
  end

  describe "invite_statuses" do
    it "returns a list of invite statuses" do
      invite_status = create(:invite_status, user_id: user.id, assignment_invitation_id: invitation.id)
      expect(invitation.invite_statuses).to eq([invite_status])
    end

    it "on #destroy destroys invite status and not the user" do
      invite_status = create(:invite_status, user_id: user.id, assignment_invitation_id: invitation.id)
      invitation.destroy
      expect { invite_status.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(user.reload.nil?).to be_falsey
    end
  end

  describe "users" do
    it "returns a list of users through invite_statuses" do
      create(:invite_status, user_id: user.id, assignment_invitation_id: invitation.id)
      expect(invitation.users).to eq([user])
    end
  end
end
