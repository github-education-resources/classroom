require 'rails_helper'

RSpec.describe Organization, type: :model do
  it { should have_many(:assignments).dependent(:destroy)       }
  it { should have_many(:groupings).dependent(:destroy)         }
  it { should have_many(:group_assignments).dependent(:destroy) }
  it { should have_many(:repo_accesses).dependent(:destroy)     }

  it { should have_and_belong_to_many(:users) }

  it { should validate_presence_of(:github_id) }
  # https://github.com/thoughtbot/shoulda-matchers/issues/745
  # it { should validate_uniqueness_of(:github_id) }

  it { should validate_presence_of(:title)   }
  # https://github.com/thoughtbot/shoulda-matchers/issues/745
  # it { should validate_uniqueness_of(:title) }

  it 'should validate that there is at least one user on the organization' do
    organization = create(:organization)
    expect(organization.valid?).to be(true)

    organization.users.destroy_all
    organization.save

    expect(organization.errors.count).to be(1)
  end

  describe '#all_assignments' do
    let(:organization) { create(:organization) }

    context 'without Assignments or GroupAssignments' do
      it 'should return an empty array' do
        expect(organization.all_assignments.class).to be(Array)
        expect(organization.all_assignments.count).to eql(0)
      end
    end

    context 'with Assignments and GroupAssignments' do
      before do
        grouping = Grouping.new(title: 'Grouping', organization: organization)
        Assignment.create(title: 'Assignment', organization: organization)
        GroupAssignment.create(title: 'Group Assignment', grouping: grouping, organization: organization)
      end

      it 'should return an array of Assignments and GroupAssignments' do
        expect(organization.all_assignments.class).to be(Array)
        expect(organization.all_assignments.count).to eql(2)
      end
    end
  end

  describe '#fetch_owner' do
    let(:organization) { create(:organization) }

    it 'selects a user at random' do
      expect(organization.fetch_owner.class).to eql(User)
    end
  end
end
