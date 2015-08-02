require 'rails_helper'

RSpec.describe Organization, type: :model do
  it { is_expected.to have_many(:assignments).dependent(:destroy)       }
  it { is_expected.to have_many(:groupings).dependent(:destroy)         }
  it { is_expected.to have_many(:group_assignments).dependent(:destroy) }
  it { is_expected.to have_many(:repo_accesses).dependent(:destroy)     }

  it { is_expected.to have_and_belong_to_many(:users) }

  describe 'validation and uniqueness' do
    subject { build(:organization) }

    it { is_expected.to validate_presence_of(:github_id) }
    it { is_expected.to validate_presence_of(:title)     }

    it { is_expected.to validate_uniqueness_of(:github_id) }
    it { is_expected.to validate_uniqueness_of(:title)     }
  end

  describe 'callbacks' do
    describe 'after_save' do
      describe '#validate_minimum_number_of_users' do
        subject { create(:organization) }

        it 'validates that there is at least one user' do
          subject.users.destroy_all
          subject.save

          expect(subject.errors.count).to be(1)
        end
      end
    end
  end

  describe '#all_assignments' do
    subject { create(:organization) }

    context 'new Organization' do
      it 'returns an empty array' do
        expect(subject.all_assignments).to be_kind_of(Array)
        expect(subject.all_assignments.count).to eql(0)
      end
    end

    context 'with Assignments and GroupAssignments' do
      let(:creator) { subject.users.first }

      before do
        grouping = Grouping.new(title: 'Grouping', organization: subject)

        Assignment.create(creator: creator, title: 'Assignment', organization: subject)
        GroupAssignment.create(creator: creator,
                               grouping: grouping,
                               organization: subject,
                               title: 'Group Assignment')
      end

      it 'should return an array of Assignments and GroupAssignments' do
        expect(subject.all_assignments).to be_kind_of(Array)
        expect(subject.all_assignments.count).to eql(2)
      end
    end
  end

  describe '#github_client' do
    let(:organization) { create(:organization) }

    it 'selects a users github_client at random' do
      expect(organization.github_client.class).to eql(Octokit::Client)
    end
  end
end
