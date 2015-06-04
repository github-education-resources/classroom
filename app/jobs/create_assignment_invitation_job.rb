class CreateAssignmentInvitationJob < ActiveJob::Base
  queue_as :default

  def perform(assignment, user, organization)
    invitation = Invitation.new(assignment: assignment,
                                team_id: organization.students_team_id,
                                title: organization.title,
                                user: user,
                                organization: organization)
    invitation.save!
  end
end
