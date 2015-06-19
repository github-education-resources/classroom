class CreateGroupAssignmentInvitationJob < ActiveJob::Base
  queue_as :default

  def perform(group_assignment)
    @invitation = group_assignment.build_group_assignment_invitation
    @invitation.save!
  end
end
