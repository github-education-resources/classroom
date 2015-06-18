require 'test_helper'

class CreateAssignmentInvitationJobTest < ActiveJob::TestCase
  test '#job creates a valid invitation for the assignment' do
    assignment = create(:assignment_with_organization)
    CreateAssignmentInvitationJob.perform_now(assignment)
    assert assignment.assignment_invitation.present?
  end
end
