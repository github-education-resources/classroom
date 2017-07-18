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

  describe "#redeem_for", :vcr do
    let(:student)       { classroom_student }
    let(:organization)  { classroom_org     }

    let(:group_assignment) do
      create(:group_assignment,
             title: "JavaScript",
             organization: organization,
             public_repo: false)
    end

    subject { create(:group_assignment_invitation, group_assignment: group_assignment) }

    after(:each) do
      RepoAccess.destroy_all
      Group.destroy_all
      GroupAssignmentRepo.destroy_all
    end

    it "returns the GroupAssignmentRepo" do
      group_assignment_repo = subject.redeem_for(student, nil, "Code Squad")
      expect(group_assignment_repo).to eql(GroupAssignmentRepo.last)
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
end
