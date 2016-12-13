# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AssignmentInvitation, type: :model do
  it_behaves_like 'a default scope where deleted_at is not present'

  it 'should have a key after initialization' do
    assignment_invitation = AssignmentInvitation.new
    expect(assignment_invitation.key).to_not be_nil
  end

  describe '#redeem_for', :vcr do
    let(:invitee)       { GitHubFactory.create_classroom_student }
    let(:organization)  { GitHubFactory.create_owner_classroom_org }

    let(:assignment)            { create(:assignment, title: 'Ruby', organization: organization) }
    let(:assignment_invitation) { create(:assignment_invitation, assignment: assignment)         }

    after(:each) do
      AssignmentRepo.destroy_all
    end

    it 'returns a AssignmentRepo::Creator::Result with the assignment repo' do
      result = assignment_invitation.redeem_for(invitee)
      expect(result.success?).to be_truthy
      expect(result.assignment_repo).to eql(AssignmentRepo.last)
    end
  end

  describe '#title' do
    let(:assignment_invitation) { create(:assignment_invitation) }

    it 'returns the assignments title' do
      assignment_title = assignment_invitation.assignment.title
      expect(assignment_invitation.title).to eql(assignment_title)
    end
  end

  describe '#to_param' do
    let(:assignment_invitation) { create(:assignment_invitation) }

    it 'should return the key' do
      expect(assignment_invitation.to_param).to eql(assignment_invitation.key)
    end
  end
end
