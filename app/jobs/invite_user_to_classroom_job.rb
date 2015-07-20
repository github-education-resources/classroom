class InviteUserToClassroomJob < ActiveJob::Base
  queue_as :default

  def perform(github_id, github_login, user_email, invitor, organization)
    user        = User.find_or_create_by(uid: github_id)
    user.status = 'pending' if user.new_record?
    user.organizations << organization
    user.save!

    UserMailer.invite_user_to_classroom(github_login, user_email, invitor, organization).deliver_now
  end
end
