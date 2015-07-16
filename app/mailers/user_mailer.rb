class UserMailer < ApplicationMailer
  def invite_user_to_classroom(user_github_login, email, invitor, organization)
    invitor_github_user = invitor.github_client.user

    @classroom  = organization.title
    @invitor    = invitor_github_user.name || invitor_github_user.login
    @user       = user_github_login

    subject_line = "[Classroom] #{@invitor_github_user} has invited you to join the #{@classroom} classroom"
    mail(to: email, subject: subject_line)
  end
end
