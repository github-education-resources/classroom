# frozen_string_literal: true

require "rails_helper"

RSpec.describe GroupAssignmentInvitation, type: :model do
  it "should have a key after initialization" do
    group_assignment_invitation = build(:group_assignment_invitation)
    expect(group_assignment_invitation.key).to_not be_nil
  end

  describe "short_key" do
    it "allows multiple invitations with nil short_key" do
      first_inv = create(:group_assignment_invitation)
      second_inv = create(:group_assignment_invitation)

      first_inv.update_attributes!(short_key: nil)
      second_inv.short_key = nil

      expect(second_inv.save).to be_truthy
    end
  end

  describe "#status", :vcr do
    let(:organization) { classroom_org }
    let(:grouping)     { create(:grouping, organization: organization) }
    let(:group)        { create(:group, grouping: grouping) }
    let(:invitation)   { create(:group_assignment_invitation) }

    it "should create an invite status for a group when one does not exist" do
      expect(GroupInviteStatus).to receive(:create).with(group: group, group_assignment_invitation: invitation)
      invitation.status(group)
    end

    it "should find an invite status for a group when one does exist" do
      expect(invitation.group_invite_statuses).to receive(:find_by).with(group: group)
      invitation.status(group)
    end

    it "returns the GroupInviteStatus that belongs to the group and the invite" do
      invite_status = GroupInviteStatus.create(group: group, group_assignment_invitation: invitation)
      expect(invitation.status(group)).to eq(invite_status)
    end
  end

  describe "#redeem_for", :vcr do
    let(:student)       { classroom_student }
    let(:grouping)      { create(:grouping, organization: organization) }
    let(:organization)  { classroom_org }
    let(:group_name)    { "#{Faker::Company.name} Team" }
    let(:group_assignment) do
      create(
        :group_assignment,
        title: "JavaScript",
        organization: organization,
        public_repo: false
      )
    end

    subject { create(:group_assignment_invitation, group_assignment: group_assignment) }

    context "success result" do
      it "returns the GroupAssignmentRepo" do
        result = subject.redeem_for(student, nil, group_name)
        expect(result.group_assignment_repo).to eql(GroupAssignmentRepo.last)
      end
    end

    context "disabled invitation" do
      before do
        expect(subject).to receive(:enabled?).and_return(false)
      end

      it "failed?" do
        result = subject.redeem_for(student, nil, group_name)
        expect(result.failed?).to be_truthy
      end

      it "fails when the invitation is not enabled?" do
        result = subject.redeem_for(student, nil, group_name)
        expect(result.error).to eq("Invitations for this assignment have been disabled.")
      end
    end

    describe "import resiliency enabled" do
      it "pending?" do
        result = subject.redeem_for(student, nil, group_name)
        expect(result.pending?).to be_truthy
      end

      it "doesn't return an GroupAssignmentRepo" do
        result = subject.redeem_for(student, nil, group_name)
        expect(result.group_assignment_repo).to be_nil
      end

      it "changes the invite status to accepted" do
        subject.redeem_for(student, nil, group_name)
        expect(subject.status(Group.all.first).accepted?).to be_truthy
      end
    end
  end

  context "with invitation" do
    subject { create(:group_assignment_invitation) }

    describe "#title" do
      it "returns the group assignments title" do
        group_assignment_title = subject.group_assignment.title
        expect(subject.title).to eql(group_assignment_title)
      end
    end

    describe "#to_param" do
      it "should return the key" do
        expect(subject.to_param).to eql(subject.key)
      end
    end
  end

  describe "group_invite_statuses", :vcr do
    let(:organization) { classroom_org }
    let(:grouping)     { create(:grouping, organization: organization) }
    let(:group)        { create(:group, grouping: grouping) }
    let(:invitation)   { create(:group_assignment_invitation) }

    it "returns a list of invite statuses" do
      group_invite_status = create(:group_invite_status, group: group, group_assignment_invitation: invitation)
      expect(invitation.group_invite_statuses).to eq([group_invite_status])
    end

    it "on #destroy destroys invite status and not the group" do
      group_invite_status = create(:group_invite_status, group: group, group_assignment_invitation: invitation)
      invitation.destroy
      expect { group_invite_status.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(group.reload.nil?).to be_falsey
    end
  end
end
