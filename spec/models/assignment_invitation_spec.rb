require 'rails_helper'

RSpec.describe AssignmentInvitation, type: :model do
  it { is_expected.to have_one(:organization).through(:assignment) }

  it { is_expected.to belong_to(:assignment) }

  it_behaves_like 'a default scope where deleted_at is not present'

  describe 'validations and uniqueness' do
    subject { AssignmentInvitation.new }

    it { is_expected.to validate_presence_of(:assignment) }

    it { is_expected.to validate_presence_of(:key)   }
    it { is_expected.to validate_uniqueness_of(:key) }
  end

  it 'should have a key after initialization' do
    assignment_invitation = AssignmentInvitation.new
    expect(assignment_invitation.key).to_not be_nil
  end

  describe '#redeem_for', :vcr do
    let(:invitee)       { GitHubFactory.create_classroom_student }
    let(:organization)  { GitHubFactory.create_owner_classroom_org }

    let(:assignment) do
      Assignment.create(creator: organization.users.first,
                        title: 'Ruby',
                        organization: organization,
                        public_repo: false)
    end

    let(:assignment_invitation) { AssignmentInvitation.create(assignment: assignment) }

    after(:each) do
      RepoAccess.destroy_all
      AssignmentRepo.destroy_all
    end

    it 'returns the full repo name of the users GitHub repository' do
      github_login   = GitHubUser.new(invitee.github_client).login
      full_repo_name = assignment_invitation.redeem_for(invitee)
      expect(full_repo_name).to eql("#{organization.title}/#{assignment.title}-#{github_login}")
    end
  end

  describe '#title' do
    let(:assignment_invitation) { create(:assignment_invitation) }

    it 'returns the assignments title' do
      assignment_title = assignment_invitation.assignment.title
      expect(assignment_invitation.title).to eql(assignment_title)
    end
  end

  describe '#to_param' do
    let(:assignment_invitation) { create(:assignment_invitation) }

    it 'should return the key' do
      expect(assignment_invitation.to_param).to eql(assignment_invitation.key)
    end
  end
end
