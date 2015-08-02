require 'rails_helper'

RSpec.describe CreateAssignmentInvitationJob, type: :job do
  it 'creates a vaild invitation for the assignment' do
    assignment = create(:assignment)

    assert_performed_with(job: CreateAssignmentInvitationJob, args: [assignment], queue: 'default') do
      CreateAssignmentInvitationJob.perform_later(assignment)
    end

    expect(assignment.assignment_invitation).to be_present
  end
end
