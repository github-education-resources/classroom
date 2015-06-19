require 'rails_helper'

RSpec.describe CreateAssignmentInvitationJob, type: :job do
  it 'creates a vaild invitation for the assignment' do
    assignment = create(:assignment_with_organization)
    CreateAssignmentInvitationJob.perform_now(assignment)

    expect(assignment.assignment_invitation).to be_present
  end
end
