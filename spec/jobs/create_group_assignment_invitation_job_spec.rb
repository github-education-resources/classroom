require 'rails_helper'

RSpec.describe CreateGroupAssignmentInvitationJob, type: :job do
  it 'creates a vaild invitation for the group_assignment' do
    group_assignment = create(:group_assignment)

    assert_performed_with(job: CreateGroupAssignmentInvitationJob, args: [group_assignment], queue: 'default') do
      CreateGroupAssignmentInvitationJob.perform_later(group_assignment)
    end

    expect(group_assignment.group_assignment_invitation).to be_present
  end
end
