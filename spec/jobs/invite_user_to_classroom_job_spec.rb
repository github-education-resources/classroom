require 'rails_helper'

RSpec.describe InviteUserToClassroomJob, type: :job do
  let(:organization) { GitHubFactory.create_owner_classroom_org }
  let(:invitor)      { organization.users.first                 }
  let(:invitee)      { GitHubFactory.create_classroom_student   }

  it 'creates sends an Invitation email', :vcr do
    expect do
      InviteUserToClassroomJob.perform_now(invitee.uid, 'test-email@gmail.com', invitor, organization)
    end.to change { ActionMailer::Base.deliveries.size }.by(1)
  end

  it 'creates a new pending user if the user does not exist', :vcr do
    InviteUserToClassroomJob.perform_now(12_345, 'testemail@gmail.com', invitor, organization)
    expect(User.last.state).to eql('pending')
  end
end
