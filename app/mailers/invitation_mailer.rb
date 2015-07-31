class InvitationMailer < ApplicationMailer
  def invite_user_to_classroom(invitee, invitee_email, invitor, organization)
    invitee_github_user = GitHubUser.new(invitor.github_client, invitee.uid).user
    invitor_github_user = GitHubUser.new(invitor.github_client).user

    @classroom = organization.title
    @invitee   = invitee_github_user.name || invitee_github_user.login
    @invitor   = invitor_github_user.name || invitor_github_user.login

    subject_line = "[Classroom] #{@invitor} has invited you to join the #{@classroom} classroom"
    mail(to: invitee_email, subject: subject_line)
  end
end
