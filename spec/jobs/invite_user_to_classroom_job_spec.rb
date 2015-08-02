require 'rails_helper'

RSpec.describe InviteUserToClassroomJob, type: :job do
  let(:organization) { GitHubFactory.create_owner_classroom_org }
  let(:invitor)      { organization.users.first                 }
  let(:invitee)      { GitHubFactory.create_classroom_student   }

  it 'creates sends an Invitation email', :vcr do
    assert_performed_with(
      job: InviteUserToClassroomJob,
      args: [invitee.uid, 'test-email@gmail.com', invitor, organization], queue: 'default'
    ) do
      expect do
        InviteUserToClassroomJob.perform_later(invitee.uid, 'test-email@gmail.com', invitor, organization)
      end.to change { ActionMailer::Base.deliveries.size }.by(1)
    end
  end

  it 'creates a new pending user if the user does not exist', :vcr do
    InviteUserToClassroomJob.perform_now(12_345, 'testemail@gmail.com', invitor, organization)
    expect(User.last.state).to eql('pending')
  end
end
