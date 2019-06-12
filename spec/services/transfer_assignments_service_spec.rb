# frozen_string_literal: true

require "rails_helper"

describe TransferAssignmentsService do
  let(:organization) { classroom_org }
  let(:old_user) { classroom_teacher }
  let(:new_user) { create(:user) }

  before(:each) do
    organization.users << new_user
    organization.save
  end

  context "when teacher owns no assignments" do
    let(:transfer_assignment_service) { TransferAssignmentsService.new(organization, old_user) }
    it "is expected to return false" do
      expect(transfer_assignment_service.transfer).to be_falsey
    end
  end

  context "when teacher owns individual assignments" do
    it "is expected to transfer assignments to random new user" do
      assignment = create(:assignment, organization: organization, creator: old_user)
      TransferAssignmentsService.new(organization, old_user).transfer
      assignment.reload
      expect(assignment.creator_id).not_to eq(old_user.id)
    end

    it "is expected to transfer assignments to specified new user" do
      assignment = create(:assignment, organization: organization, creator: old_user)
      TransferAssignmentsService.new(organization, old_user, new_user).transfer
      assignment.reload
      expect(assignment.creator_id).to eq(new_user.id)
    end
  end

  context "when teacher owns group assignments" do
    it "is expected to transfer group assignments to random new user" do
      assignment = create(:group_assignment, organization: organization, creator: old_user)
      TransferAssignmentsService.new(organization, old_user).transfer
      assignment.reload
      expect(assignment.creator_id).not_to eq(old_user.id)
    end

    it "is expected to transfer group assignments to specified new user" do
      assignment = create(:group_assignment, organization: organization, creator: old_user)
      TransferAssignmentsService.new(organization, old_user, new_user).transfer
      assignment.reload
      expect(assignment.creator_id).to eq(new_user.id)
    end
  end
end
