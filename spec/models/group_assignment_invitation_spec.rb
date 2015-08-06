require 'rails_helper'

RSpec.describe GroupAssignmentInvitation, type: :model do
  it { is_expected.to have_one(:grouping).through(:group_assignment)     }
  it { is_expected.to have_one(:organization).through(:group_assignment) }

  it { is_expected.to have_many(:groups).through(:grouping) }

  it { is_expected.to belong_to(:group_assignment) }

  it_behaves_like 'a default scope where deleted_at is not present'

  describe 'validations and uniqueness' do
    subject { GroupAssignmentInvitation.new }

    it { is_expected.to validate_presence_of(:group_assignment) }

    it { is_expected.to validate_presence_of(:key)   }
    it { is_expected.to validate_uniqueness_of(:key) }
  end

  it 'should have a key after initialization' do
    group_assignment_invitation = GroupAssignmentInvitation.new
    expect(group_assignment_invitation.key).to_not be_nil
  end

  describe '#redeem_for', :vcr do
    let(:invitee)       { GitHubFactory.create_classroom_student   }
    let(:organization)  { GitHubFactory.create_owner_classroom_org }
    let(:grouping)      { Grouping.create(title: 'Grouping', organization: organization) }

    let(:group_assignment)  do
      GroupAssignment.create(creator: organization.users.first,
                             title: 'JavaScript',
                             organization: organization,
                             public_repo: false,
                             grouping: grouping)
    end

    let(:group_assignment_invitation) { GroupAssignmentInvitation.create(group_assignment: group_assignment) }

    after(:each) do
      RepoAccess.destroy_all
      Group.destroy_all
      GroupAssignmentRepo.destroy_all
    end

    it 'returns the full repo name of the users GitHub repository' do
      full_repo_name = group_assignment_invitation.redeem_for(invitee, nil, 'Code Squad')
      expect(full_repo_name).to eql("#{organization.title}/#{group_assignment.title}-Code-Squad")
    end
  end

  describe '#to_param' do
    let(:group_assignment_invitation) { create(:group_assignment_invitation) }

    it 'should return the key' do
      expect(group_assignment_invitation.to_param).to eql(group_assignment_invitation.key)
    end
  end
end
