class InviteUserToClassroomJob < ActiveJob::Base
  queue_as :default

  def perform(github_id, invitee_email, invitor, organization)
    invitee = User.find_or_create_by(uid: github_id)

    if invitee.new_record?
      invitee.state = 'pending'
      invitee.save!
    end

    invitee.organizations << organization

    InvitationMailer.invite_user_to_classroom(invitee, invitee_email, invitor, organization).deliver_now
  end
end
