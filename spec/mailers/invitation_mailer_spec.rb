require 'rails_helper'

RSpec.describe InvitationMailer, type: :mailer do
  describe '#invite_user_to_classroom', :vcr do
    let(:organization) { GitHubFactory.create_owner_classroom_org }
    let(:invitor)      { organization.users.first                 }
    let(:invitee)      { GitHubFactory.create_classroom_student   }

    let(:mail) { InvitationMailer.invite_user_to_classroom(invitee, 'test@gmail.com', invitor, organization) }

    it 'renders the subject' do
      github_invitor = GitHubUser.new(invitor.github_client).user
      invitor_name   = github_invitor.name || github_invitor.login

      subject_line = "[Classroom] #{invitor_name} has invited you to join the #{organization.title} classroom"
      expect(mail.subject).to include(subject_line)
    end

    it 'renders the reciever email' do
      expect(mail.to).to eq(['test@gmail.com'])
    end

    it 'includes the login url' do
      expect(mail.body.encoded).to match(login_url)
    end
  end
end
