class CreateAssignmentInvitationJob < ActiveJob::Base
  queue_as :default

  def perform(assignment)
    invitation = assignment.build_assignment_invitation
    invitation.save!
  end
end
